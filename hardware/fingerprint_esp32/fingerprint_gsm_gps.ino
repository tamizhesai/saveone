#include <Adafruit_Fingerprint.h>
#include <TinyGPS++.h>
#include <HardwareSerial.h>

// Hardware Serial Definitions
HardwareSerial fingerSerial(1);  // RX=GPIO16, TX=GPIO17
HardwareSerial gpsSerial(2);     // RX=GPIO4, TX=GPIO2
HardwareSerial gsmSerial(0);     // RX=GPIO3, TX=GPIO1 (default Serial)

Adafruit_Fingerprint finger = Adafruit_Fingerprint(&fingerSerial);
TinyGPSPlus gps;

// Backend phone number for SMS notifications
const char* backendPhone = "+919876543210";  // UPDATE THIS

uint8_t newID = 1;
double currentLat = 0.0;
double currentLng = 0.0;
bool gpsFixed = false;

void setup() {
  Serial.begin(9600);  // GSM module
  delay(2000);
  
  Serial.println("=== SaveOne Security System ===");
  
  // Initialize Fingerprint Sensor
  fingerSerial.begin(57600, SERIAL_8N1, 16, 17);
  finger.begin(57600);
  
  Serial.println("Initializing Fingerprint Sensor...");
  if (!finger.verifyPassword()) {
    Serial.println("ERROR: Fingerprint sensor not detected!");
    while (1) delay(1000);
  }
  Serial.println("OK: Fingerprint sensor ready");
  
  // Initialize GPS
  gpsSerial.begin(9600, SERIAL_8N1, 4, 2);
  Serial.println("Initializing GPS...");
  Serial.println("OK: GPS module ready");
  
  // Initialize GSM
  delay(3000);
  Serial.println("Initializing GSM...");
  sendATCommand("AT", 1000);
  sendATCommand("AT+CMGF=1", 1000);  // SMS text mode
  sendATCommand("AT+CNMI=2,2,0,0,0", 1000);  // SMS notification
  Serial.println("OK: GSM module ready");
  
  findNextFreeID();
  Serial.println("\n=== System Ready ===");
  Serial.println("Place finger on sensor...\n");
}

void loop() {
  // Update GPS data
  updateGPS();
  
  // Check for fingerprint
  uint8_t p = finger.getImage();
  if (p != FINGERPRINT_OK) return;

  p = finger.image2Tz();
  if (p != FINGERPRINT_OK) return;

  // Search for fingerprint
  p = finger.fingerFastSearch();
  
  if (p == FINGERPRINT_OK) {
    // Existing fingerprint found
    handleExistingFingerprint(finger.fingerID);
  } else {
    // New fingerprint detected
    handleNewFingerprint();
  }
}

// ---------- HANDLE EXISTING FINGERPRINT ----------
void handleExistingFingerprint(uint8_t id) {
  Serial.println("\n=== FINGERPRINT RECOGNIZED ===");
  Serial.print("Fingerprint ID: ");
  Serial.println(id);
  
  // Get GPS location
  Serial.print("Location: ");
  if (gpsFixed) {
    Serial.print("Lat=");
    Serial.print(currentLat, 6);
    Serial.print(", Lng=");
    Serial.println(currentLng, 6);
  } else {
    Serial.println("GPS not fixed");
  }
  
  // Send SMS to backend
  String message = "AUTH:ID=" + String(id);
  if (gpsFixed) {
    message += ",LAT=" + String(currentLat, 6);
    message += ",LNG=" + String(currentLng, 6);
  }
  sendSMS(backendPhone, message);
  
  Serial.println("Authentication sent to backend");
  Serial.println("==============================\n");
  
  delay(3000);
}

// ---------- HANDLE NEW FINGERPRINT ----------
void handleNewFingerprint() {
  Serial.println("\n=== NEW FINGERPRINT DETECTED ===");
  Serial.print("Enrolling as ID: ");
  Serial.println(newID);
  
  if (enrollNewFingerprint(newID)) {
    // Get GPS location
    Serial.print("Location: ");
    if (gpsFixed) {
      Serial.print("Lat=");
      Serial.print(currentLat, 6);
      Serial.print(", Lng=");
      Serial.println(currentLng, 6);
    } else {
      Serial.println("GPS not fixed");
    }
    
    // Send SMS notification
    String message = "NEW:ID=" + String(newID);
    if (gpsFixed) {
      message += ",LAT=" + String(currentLat, 6);
      message += ",LNG=" + String(currentLng, 6);
    }
    message += " - Complete signup on app";
    sendSMS(backendPhone, message);
    
    Serial.println("New fingerprint notification sent");
    Serial.println("Please complete signup on Flutter app");
    Serial.println("================================\n");
    
    newID++;
  }
}

// ---------- ENROLL FINGERPRINT ----------
bool enrollNewFingerprint(uint8_t id) {
  Serial.println("\nRemove finger...");
  delay(2000);
  while (finger.getImage() != FINGERPRINT_NOFINGER);

  Serial.println("Place SAME finger again...");
  while (finger.getImage() != FINGERPRINT_OK);

  if (finger.image2Tz(2) != FINGERPRINT_OK) {
    Serial.println("ERROR: Image conversion failed");
    return false;
  }

  if (finger.createModel() != FINGERPRINT_OK) {
    Serial.println("ERROR: Fingers did not match");
    return false;
  }

  if (finger.storeModel(id) == FINGERPRINT_OK) {
    Serial.println("SUCCESS: Fingerprint saved");
    return true;
  } else {
    Serial.println("ERROR: Failed to save fingerprint");
    return false;
  }
}

// ---------- GPS UPDATE ----------
void updateGPS() {
  while (gpsSerial.available() > 0) {
    char c = gpsSerial.read();
    if (gps.encode(c)) {
      if (gps.location.isValid()) {
        currentLat = gps.location.lat();
        currentLng = gps.location.lng();
        gpsFixed = true;
      }
    }
  }
}

// ---------- GSM FUNCTIONS ----------
void sendSMS(const char* number, String message) {
  Serial.println("\nSending SMS...");
  
  sendATCommand("AT+CMGF=1", 1000);
  
  String cmd = "AT+CMGS=\"";
  cmd += number;
  cmd += "\"";
  Serial.println(cmd);
  delay(1000);
  
  Serial.print(message);
  delay(100);
  Serial.write(26);  // Ctrl+Z
  delay(5000);
  
  Serial.println("SMS sent");
}

void sendATCommand(String command, int timeout) {
  Serial.println(command);
  long int time = millis();
  while ((time + timeout) > millis()) {
    while (Serial.available()) {
      char c = Serial.read();
    }
  }
}

// ---------- FIND FREE ID ----------
void findNextFreeID() {
  for (uint8_t i = 1; i < 127; i++) {
    if (finger.loadModel(i) != FINGERPRINT_OK) {
      newID = i;
      break;
    }
  }
}
