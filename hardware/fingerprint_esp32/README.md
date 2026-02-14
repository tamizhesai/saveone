# ESP32 Fingerprint Authentication Setup

## Hardware Requirements
- ESP32 Development Board
- Adafruit Fingerprint Sensor (R307/AS608)
- LED (connected to GPIO 25)
- Jumper wires

## Wiring
```
Fingerprint Sensor -> ESP32
VCC (Red)          -> 3.3V
GND (Black)        -> GND
TX (White)         -> GPIO 16 (RX2)
RX (Green)         -> GPIO 17 (TX2)

LED                -> GPIO 25 (with resistor)
```

## Arduino IDE Setup

1. Install Arduino IDE
2. Add ESP32 board support:
   - File > Preferences
   - Additional Board URLs: `https://dl.espressif.com/dl/package_esp32_index.json`
   - Tools > Board > Boards Manager > Search "ESP32" > Install

3. Install Required Libraries:
   - Sketch > Include Library > Manage Libraries
   - Install: `Adafruit Fingerprint Sensor Library`
   - Install: `ArduinoJson` (version 6.x)

4. Configure WiFi and Server:
   - Open `fingerprint_esp32.ino`
   - Update `ssid` with your WiFi name
   - Update `password` with your WiFi password
   - Update `serverUrl` with your computer's local IP (find using `ipconfig` or `ifconfig`)
   - Example: `http://192.168.1.100:3000/api/fingerprint`

5. Upload to ESP32:
   - Tools > Board > ESP32 Dev Module
   - Tools > Port > Select your ESP32 port
   - Click Upload

## How It Works

### New Fingerprint Flow:
1. User places finger on sensor
2. ESP32 detects it's a new fingerprint
3. LED blinks slowly (3 times)
4. ESP32 enrolls fingerprint with ID (e.g., ID=1)
5. Serial monitor shows: "New fingerprint ID: 1"
6. User must complete signup on Flutter app with this fingerprint ID

### Existing Fingerprint Flow:
1. User places finger on sensor
2. ESP32 recognizes fingerprint (e.g., ID=1)
3. ESP32 sends HTTP request to backend: `/api/fingerprint/check`
4. Backend checks if user exists with fingerprint_id=1
5. If user exists: LED stays on for 2 seconds, shows "Welcome, [Name]"
6. If no user: LED blinks slowly, shows "Please complete signup"

## Serial Monitor Output Examples

### New Fingerprint:
```
✅ Fingerprint found. ID = 1
Checking fingerprint with backend...
Response: {"exists":false}
⚠️ Fingerprint enrolled but no user account
Please complete signup on the app
```

### Existing User Login:
```
✅ Fingerprint found. ID = 1
Checking fingerprint with backend...
Response: {"exists":true,"user":{"id":1,"name":"John Doe",...}}
🔓 User authenticated!
Welcome, John Doe
```

## Troubleshooting

1. **Sensor not detected**: Check wiring, ensure 3.3V power
2. **WiFi not connecting**: Verify SSID/password, check 2.4GHz network
3. **HTTP Error**: Ensure backend server is running, check IP address
4. **Fingerprint not saving**: Clean sensor, press finger firmly

## LED Patterns

- **Fast blink (6 times)**: Existing fingerprint recognized
- **Slow blink (3 times)**: New fingerprint or no user account
- **Continuous blink**: Error state
- **Solid 2 seconds**: Successful authentication
