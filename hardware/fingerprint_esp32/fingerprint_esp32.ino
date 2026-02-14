#include <Adafruit_Fingerprint.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

#define LED_PIN 25

// WiFi credentials - UPDATE THESE
const char* ssid = "esai";
const char* password = "esaiphone";

// Backend server URL - UPDATE THIS (use your computer's local IP)
const char* serverUrl = "http://10.218.63.223:3000/api/fingerprint";

HardwareSerial fingerSerial(2);
Adafruit_Fingerprint finger = Adafruit_Fingerprint(&fingerSerial);

uint8_t newID = 1;
bool wifiConnected = false;

void setup() {
  Serial.begin(115200);
  delay(1000);

  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  connectWiFi();

  fingerSerial.begin(57600, SERIAL_8N1, 16, 17);
  finger.begin(57600);

  Serial.println("Initializing Fingerprint Sensor...");

  if (!finger.verifyPassword()) {
    Serial.println("❌ Sensor NOT detected!");
    errorBlink();
    while (1);
  }

  Serial.println("✅ Sensor detected");
  findNextFreeID();
  Serial.println("Place your finger...");
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi disconnected. Reconnecting...");
    connectWiFi();
  }

  uint8_t p = finger.getImage();
  if (p != FINGERPRINT_OK) return;

  p = finger.image2Tz();
  if (p != FINGERPRINT_OK) return;

  p = finger.fingerFastSearch();
  
  if (p == FINGERPRINT_OK) {
    uint8_t fingerprintID = finger.fingerID;
    Serial.print("✅ Fingerprint found. ID = ");
    Serial.println(fingerprintID);
    
    // Send to Flutter app for login
    sendFingerprintToBackend(fingerprintID, "login");
    
    // Check authentication
    checkFingerprintWithBackend(fingerprintID);
    
    fastBlink();
    delay(2000);
    return;
  }

  Serial.println("🆕 New fingerprint detected");
  slowBlink();
  
  if (enrollNewFingerprint(newID)) {
    // Send to Flutter app for signup
    sendFingerprintToBackend(newID, "signup");
    notifyNewFingerprint(newID);
    newID++;
  }
}

void connectWiFi() {
  Serial.print("Connecting to WiFi");
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println();
    Serial.println("✅ WiFi connected");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
    wifiConnected = true;
  } else {
    Serial.println();
    Serial.println("❌ WiFi connection failed");
    wifiConnected = false;
  }
}

void checkFingerprintWithBackend(uint8_t fingerprintID) {
  if (!wifiConnected) {
    Serial.println("❌ No WiFi connection");
    return;
  }

  HTTPClient http;
  String url = String(serverUrl) + "/check";
  
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  
  StaticJsonDocument<200> doc;
  doc["fingerprint_id"] = fingerprintID;
  
  String jsonString;
  serializeJson(doc, jsonString);
  
  Serial.println("Checking fingerprint with backend...");
  int httpResponseCode = http.POST(jsonString);
  
  if (httpResponseCode > 0) {
    String response = http.getString();
    Serial.println("Response: " + response);
    
    StaticJsonDocument<512> responseDoc;
    deserializeJson(responseDoc, response);
    
    bool exists = responseDoc["exists"];
    
    if (exists) {
      Serial.println("🔓 User authenticated!");
      const char* userName = responseDoc["user"]["name"];
      Serial.print("Welcome, ");
      Serial.println(userName);
      
      digitalWrite(LED_PIN, HIGH);
      delay(2000);
      digitalWrite(LED_PIN, LOW);
    } else {
      Serial.println("⚠️ Fingerprint enrolled but no user account");
      Serial.println("Please complete signup on the app");
      slowBlink();
    }
  } else {
    Serial.print("❌ HTTP Error: ");
    Serial.println(httpResponseCode);
  }
  
  http.end();
}

void sendFingerprintToBackend(uint8_t fingerprintID, const char* type) {
  if (!wifiConnected) {
    Serial.println("❌ No WiFi - cannot send to Flutter app");
    return;
  }

  HTTPClient http;
  String url = String(serverUrl) + "/scan";
  
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  
  StaticJsonDocument<200> doc;
  doc["fingerprint_id"] = fingerprintID;
  doc["type"] = type;
  
  String jsonString;
  serializeJson(doc, jsonString);
  
  Serial.print("📤 Sending to Flutter app: ");
  Serial.println(jsonString);
  
  int httpResponseCode = http.POST(jsonString);
  
  if (httpResponseCode > 0) {
    Serial.println("✅ Sent to Flutter app successfully");
  } else {
    Serial.print("❌ HTTP Error sending to Flutter: ");
    Serial.println(httpResponseCode);
  }
  
  http.end();
}

void notifyNewFingerprint(uint8_t fingerprintID) {
  Serial.print("📤 New fingerprint ID: ");
  Serial.println(fingerprintID);
  Serial.println("✅ Sent to Flutter app - Please complete signup");
}

bool enrollNewFingerprint(uint8_t id) {
  Serial.print("\n=== Enrolling Fingerprint ID ");
  Serial.print(id);
  Serial.println(" ===");
  Serial.println("IMPORTANT: Use the SAME finger, press firmly!");
  
  // Wait for finger to be removed
  Serial.println("\n1. Remove finger from sensor...");
  delay(3000);
  int timeout = 0;
  while (finger.getImage() != FINGERPRINT_NOFINGER && timeout < 50) {
    delay(100);
    timeout++;
  }
  
  if (timeout >= 50) {
    Serial.println("❌ Timeout: Please remove finger");
    errorBlink();
    return false;
  }
  
  Serial.println("✅ Finger removed");
  delay(1000);
  
  // Get second image
  Serial.println("\n2. Place SAME finger again (press FIRMLY!)...");
  timeout = 0;
  while (finger.getImage() != FINGERPRINT_OK && timeout < 100) {
    delay(100);
    timeout++;
  }
  
  if (timeout >= 100) {
    Serial.println("❌ Timeout: No finger detected");
    errorBlink();
    return false;
  }
  
  Serial.println("✅ Image captured");
  
  // Convert second image
  Serial.println("3. Processing image...");
  uint8_t p = finger.image2Tz(2);
  
  if (p != FINGERPRINT_OK) {
    Serial.println("❌ Image conversion failed");
    Serial.println("TIP: Press finger more firmly and cover entire sensor");
    errorBlink();
    return false;
  }
  
  Serial.println("✅ Image processed");
  
  // Create model
  Serial.println("4. Creating fingerprint model...");
  p = finger.createModel();
  
  if (p != FINGERPRINT_OK) {
    Serial.println("❌ Fingers did not match");
    Serial.println("TIP: Make sure you used the SAME finger both times");
    errorBlink();
    return false;
  }
  
  Serial.println("✅ Model created");
  
  // Store model
  Serial.println("5. Saving to sensor...");
  p = finger.storeModel(id);
  
  if (p == FINGERPRINT_OK) {
    Serial.println("\n✅✅✅ SUCCESS! Fingerprint saved ✅✅✅");
    Serial.print("Fingerprint ID: ");
    Serial.println(id);
    digitalWrite(LED_PIN, HIGH);
    delay(2000);
    digitalWrite(LED_PIN, LOW);
    return true;
  } else {
    Serial.println("❌ Failed to save fingerprint");
    errorBlink();
    return false;
  }
}

void findNextFreeID() {
  for (uint8_t i = 1; i < 127; i++) {
    if (finger.loadModel(i) != FINGERPRINT_OK) {
      newID = i;
      break;
    }
  }
}

void fastBlink() {
  for (int i = 0; i < 6; i++) {
    digitalWrite(LED_PIN, HIGH);
    delay(150);
    digitalWrite(LED_PIN, LOW);
    delay(150);
  }
}

void slowBlink() {
  for (int i = 0; i < 3; i++) {
    digitalWrite(LED_PIN, HIGH);
    delay(500);
    digitalWrite(LED_PIN, LOW);
    delay(500);
  }
}

void errorBlink() {
  for (int i = 0; i < 10; i++) {
    digitalWrite(LED_PIN, HIGH);
    delay(300);
    digitalWrite(LED_PIN, LOW);
    delay(300);
  }
}
