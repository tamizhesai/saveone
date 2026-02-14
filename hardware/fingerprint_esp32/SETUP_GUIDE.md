# ESP32 Fingerprint + GPS + GSM Setup Guide

## What You Have
- ESP32 Development Board
- R307 Fingerprint Sensor
- NEO-6M GPS Module
- SIM800L GSM Module
- Battery (3.7V LiPo)

## What This System Does

### New User Registration
1. User places finger on R307 sensor
2. ESP32 enrolls fingerprint (e.g., ID=5)
3. ESP32 gets GPS location
4. ESP32 sends SMS to backend: "NEW:ID=5,LAT=13.0827,LNG=80.2707"
5. User completes signup on Flutter app using fingerprint ID=5

### Existing User Login
1. User places registered finger on sensor
2. ESP32 recognizes fingerprint (ID=5)
3. ESP32 gets GPS location
4. ESP32 sends SMS: "AUTH:ID=5,LAT=13.0827,LNG=80.2707"
5. Backend verifies and logs user location

## Hardware Setup

### Step 1: SIM Card Preparation
1. Get a working SIM card with SMS capability
2. Disable PIN lock on SIM:
   - Insert SIM in phone
   - Settings → SIM card → Disable PIN
3. Ensure SIM has credit for sending SMS
4. Note down your backend phone number

### Step 2: Wiring (See WIRING_GUIDE.md)
```
R307 Fingerprint:
  VCC → ESP32 3.3V
  GND → ESP32 GND
  TX  → ESP32 GPIO16
  RX  → ESP32 GPIO17

NEO-6M GPS:
  VCC → ESP32 3.3V
  GND → ESP32 GND
  TX  → ESP32 GPIO4
  RX  → ESP32 GPIO2

SIM800L GSM:
  VCC → Battery + (3.7V-4.2V)
  GND → Battery -
  TX  → ESP32 GPIO3
  RX  → ESP32 GPIO1

Battery:
  + → ESP32 VIN
  - → ESP32 GND
```

### Step 3: Arduino IDE Setup

**Install Libraries:**
1. Sketch → Include Library → Manage Libraries
2. Install: `Adafruit Fingerprint Sensor Library`
3. Install: `TinyGPSPlus`

**Configure Code:**
1. Open `fingerprint_gsm_gps.ino`
2. Update backend phone number:
   ```cpp
   const char* backendPhone = "+919876543210";  // Your number
   ```
3. Select Board: Tools → Board → ESP32 Dev Module
4. Select Port: Tools → Port → (Your ESP32 port)
5. Click Upload

### Step 4: Testing

**Open Serial Monitor:**
- Tools → Serial Monitor
- Set baud rate: **9600**

**Expected Output:**
```
=== SaveOne Security System ===
Initializing Fingerprint Sensor...
OK: Fingerprint sensor ready
Initializing GPS...
OK: GPS module ready
Initializing GSM...
AT
OK
AT+CMGF=1
OK
OK: GSM module ready

=== System Ready ===
Place finger on sensor...
```

## Usage

### Enroll New Fingerprint

1. **Place finger on sensor**
   ```
   === NEW FINGERPRINT DETECTED ===
   Enrolling as ID: 1
   
   Remove finger...
   Place SAME finger again...
   SUCCESS: Fingerprint saved
   Location: Lat=13.082700, Lng=80.270700
   
   Sending SMS...
   SMS sent
   New fingerprint notification sent
   Please complete signup on Flutter app
   ================================
   ```

2. **Check your phone** - You'll receive SMS:
   ```
   NEW:ID=1,LAT=13.082700,LNG=80.270700 - Complete signup on app
   ```

3. **Complete signup on Flutter app**
   - Open app → Sign Up with Fingerprint
   - Enter Fingerprint ID: 1
   - Fill in details (name, email, phone, password, nominee)
   - Submit

### Login with Fingerprint

1. **Place registered finger on sensor**
   ```
   === FINGERPRINT RECOGNIZED ===
   Fingerprint ID: 1
   Location: Lat=13.082700, Lng=80.270700
   
   Sending SMS...
   SMS sent
   Authentication sent to backend
   ==============================
   ```

2. **Backend receives SMS:**
   ```
   AUTH:ID=1,LAT=13.082700,LNG=80.270700
   ```

3. **Backend verifies user and logs location**

## Serial Monitor Commands

The system uses Serial Monitor for all feedback (no LED needed):

### Initialization Messages
- `OK: Fingerprint sensor ready` - Sensor working
- `OK: GPS module ready` - GPS initialized
- `OK: GSM module ready` - GSM connected

### Fingerprint Messages
- `=== NEW FINGERPRINT DETECTED ===` - New user
- `=== FINGERPRINT RECOGNIZED ===` - Existing user
- `SUCCESS: Fingerprint saved` - Enrollment complete
- `ERROR: Fingers did not match` - Try again

### GPS Messages
- `Location: Lat=X, Lng=Y` - GPS fixed
- `GPS not fixed` - No GPS signal (move outdoors)

### GSM Messages
- `Sending SMS...` - Sending message
- `SMS sent` - Message delivered

## Troubleshooting

### "ERROR: Fingerprint sensor not detected!"
- Check wiring: TX→GPIO16, RX→GPIO17
- Try swapping TX/RX
- Verify 3.3V power

### "GPS not fixed"
- Move device near window or outdoors
- Wait 30-60 seconds for first fix
- GPS needs clear sky view

### GSM not responding
- Check SIM card inserted correctly
- Verify SIM has no PIN lock
- Ensure SIM800L powered from battery (3.7V-4.2V)
- Add 1000µF capacitor near SIM800L power pins
- Check antenna connected

### System resets randomly
- SIM800L drawing too much current
- Add large capacitor (1000µF) to SIM800L power
- Use thicker wires for SIM800L
- Use battery with higher capacity (2000mAh+)

### SMS not sending
- Check SIM has credit
- Verify phone number format: +[country code][number]
- Check network signal (SIM800L LED should blink)
- Test with AT commands manually

## Power Consumption

**Active Mode:**
- ESP32: ~240mA
- R307: ~120mA
- GPS: ~50mA
- SIM800L: ~300mA (idle), ~2A (transmitting)
- **Total: ~700mA idle, ~2.5A peak**

**Battery Life (2000mAh):**
- Continuous use: ~3-4 hours
- Standby mode: ~8-12 hours

**Power Saving Tips:**
- Implement deep sleep between scans
- Turn off GPS when not needed
- Use GSM sleep mode
- Reduce fingerprint scan frequency

## SMS Message Format

### New Fingerprint
```
NEW:ID=5,LAT=13.082700,LNG=80.270700 - Complete signup on app
```

### Authentication
```
AUTH:ID=5,LAT=13.082700,LNG=80.270700
```

### Parsing in Backend
```javascript
// Example parsing
const sms = "AUTH:ID=5,LAT=13.082700,LNG=80.270700";
const parts = sms.split(':')[1].split(',');
const id = parts[0].split('=')[1];        // "5"
const lat = parts[1].split('=')[1];       // "13.082700"
const lng = parts[2].split('=')[1];       // "80.270700"
```

## Next Steps

1. ✅ Wire all components
2. ✅ Upload code to ESP32
3. ✅ Test fingerprint enrollment
4. ✅ Verify GPS location
5. ✅ Confirm SMS sending
6. ⬜ Update backend to receive SMS
7. ⬜ Integrate with Flutter app

## Safety Notes

⚠️ **Battery Safety:**
- Never short circuit battery
- Use battery with protection circuit
- Don't leave charging unattended
- Replace damaged batteries immediately

⚠️ **SIM800L Power:**
- Must use 3.7V-4.2V (battery voltage)
- Add capacitor for stability
- Use thick wires (20 AWG minimum)

✅ **Good Practices:**
- Test each module separately first
- Double-check wiring before powering on
- Keep system away from water
- Monitor battery voltage
