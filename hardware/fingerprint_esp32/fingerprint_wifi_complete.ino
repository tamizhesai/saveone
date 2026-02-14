#include <Adafruit_Fingerprint.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

#define LED_PIN 25

// GSM Module pins - UPDATE THESE to match your wiring
#define GSM_RX 26
#define GSM_TX 27

// WiFi credentials
const char* ssid = "esai";
const char* password = "esaiphone";

// Backend server URL
const char* serverUrl = "http://10.162.138.223:3000/api/fingerprint";

HardwareSerial fingerSerial(2);
HardwareSerial gsmSerial(1);
Adafruit_Fingerprint finger = Adafruit_Fingerprint(&fingerSerial);

uint8_t newID = 1;
bool wifiConnected = false;

void setup() {
  Serial.begin(115200);
  delay(1000);

  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  connectWiFi();

  // Initialize GSM module
  gsmSerial.begin(9600, SERIAL_8N1, GSM_RX, GSM_TX);
  delay(3000);
  Serial.println("Initializing GSM module...");
  sendATCommand("AT", 1000);
  sendATCommand("AT+CMGF=1", 1000);  // SMS text mode
  Serial.println("✅ GSM module ready");

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
    
    // Send to backend for login
    sendFingerprintToBackend(fingerprintID, "login");
    checkFingerprintWithBackend(fingerprintID);
    
    fastBlink();
    delay(2000);
    return;
  }

  Serial.println("🆕 New fingerprint detected");
  slowBlink();
  
  if (enrollNewFingerprint(newID)) {
    // Send to backend for signup
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

void sendFingerprintToBackend(uint8_t fingerprintID, const char* type) {
  if (!wifiConnected) {
    Serial.println("❌ No WiFi - cannot send to backend");
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
    Serial.print("❌ HTTP Error: ");
    Serial.println(httpResponseCode);
  }
  
  http.end();
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
      const char* nomineeNumber = responseDoc["user"]["nominee_number"];
      Serial.print("Welcome, ");
      Serial.println(userName);

      // Send SMS to nominee
      if (nomineeNumber != nullptr && strlen(nomineeNumber) > 0) {
        String smsMessage = "SaveOne Alert: ";
        smsMessage += userName;
        smsMessage += " logged in via fingerprint.";
        Serial.print("📱 Sending SMS to nominee: ");
        Serial.println(nomineeNumber);
        sendSMS(nomineeNumber, smsMessage);
      }

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

void notifyNewFingerprint(uint8_t fingerprintID) {
  Serial.print("📤 New fingerprint ID: ");
  Serial.println(fingerprintID);
  Serial.println("✅ Sent to Flutter app - Please complete signup");
}

bool enrollNewFingerprint(uint8_t id) {
  Serial.print("Saving as ID ");
  Serial.println(id);

  Serial.println("Remove finger");
  delay(2000);
  while (finger.getImage() != FINGERPRINT_NOFINGER);

  Serial.println("Place SAME finger again");
  while (finger.getImage() != FINGERPRINT_OK);

  if (finger.image2Tz(2) != FINGERPRINT_OK) {
    Serial.println("❌ Image conversion failed");
    errorBlink();
    return false;
  }

  if (finger.createModel() != FINGERPRINT_OK) {
    Serial.println("❌ Finger mismatch");
    errorBlink();
    return false;
  }

  if (finger.storeModel(id) == FINGERPRINT_OK) {
    Serial.println("✅ Fingerprint saved to sensor");
    digitalWrite(LED_PIN, HIGH);
    delay(2000);
    digitalWrite(LED_PIN, LOW);
    return true;
  } else {
    Serial.println("❌ Save failed");
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

// ---------- GSM FUNCTIONS ----------
void sendSMS(const char* number, String message) {
  Serial.println("📱 Sending SMS...");

  sendATCommand("AT+CMGF=1", 1000);

  String cmd = "AT+CMGS=\"";
  cmd += number;
  cmd += "\"";
  gsmSerial.println(cmd);
  delay(1000);

  gsmSerial.print(message);
  delay(100);
  gsmSerial.write(26);  // Ctrl+Z to send
  delay(5000);

  Serial.println("✅ SMS sent to nominee");
}

void sendATCommand(String command, int timeout) {
  gsmSerial.println(command);
  long int startTime = millis();
  while ((startTime + timeout) > millis()) {
    while (gsmSerial.available()) {
      char c = gsmSerial.read();
      Serial.print(c);
    }
  }
}
