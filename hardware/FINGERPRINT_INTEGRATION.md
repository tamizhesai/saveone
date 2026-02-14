# Fingerprint Authentication Integration Guide

## Overview
This system integrates ESP32 fingerprint sensor with your Flutter SaveOne app and PostgreSQL backend.

## Architecture

```
┌─────────────┐      WiFi/HTTP      ┌──────────────┐      HTTP       ┌─────────────┐
│   ESP32     │ ◄──────────────────► │   Backend    │ ◄──────────────► │   Flutter   │
│  Fingerprint│                      │  (Node.js)   │                  │     App     │
│   Sensor    │                      │  PostgreSQL  │                  │             │
└─────────────┘                      └──────────────┘                  └─────────────┘
```

## Workflow

### 1. New User Registration with Fingerprint

**Step 1: ESP32 Enrollment**
- User places finger on sensor
- ESP32 detects new fingerprint
- ESP32 enrolls fingerprint with ID (e.g., ID=5)
- LED blinks slowly
- Serial monitor shows: "New fingerprint ID: 5"

**Step 2: Flutter App Signup**
- User opens Flutter app
- Clicks "Sign Up with Fingerprint"
- Enters fingerprint ID: 5
- Fills form: Name, Email, Phone, Password, Nominee Number
- App calls: `POST /api/fingerprint/register`
- Backend saves user with `fingerprint_id = 5`
- User is registered and logged in

### 2. Existing User Login with Fingerprint

**Step 1: ESP32 Recognition**
- User places finger on sensor
- ESP32 recognizes fingerprint (ID=5)
- ESP32 calls: `POST /api/fingerprint/check` with `fingerprint_id=5`

**Step 2: Backend Verification**
- Backend queries: `SELECT * FROM users WHERE fingerprint_id = 5`
- If user exists: Returns user data
- If no user: Returns `{exists: false}`

**Step 3: ESP32 Response**
- If user exists: LED solid for 2 seconds, shows "Welcome, [Name]"
- If no user: LED blinks, shows "Please complete signup"

**Step 4: Flutter App (Optional)**
- User can also login via app
- App calls: `POST /api/fingerprint/check` with fingerprint ID
- If exists: Auto-login to user profile
- If not: Show signup form

## Database Schema

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    nominee_number VARCHAR(20) NOT NULL,
    fingerprint_id INTEGER UNIQUE,  -- Links to ESP32 fingerprint ID
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## API Endpoints

### Check Fingerprint
```http
POST /api/fingerprint/check
Content-Type: application/json

{
  "fingerprint_id": 5
}

Response (User exists):
{
  "exists": true,
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "phone_number": "1234567890",
    "nominee_number": "9876543210"
  }
}

Response (No user):
{
  "exists": false
}
```

### Register with Fingerprint
```http
POST /api/fingerprint/register
Content-Type: application/json

{
  "fingerprint_id": 5,
  "name": "John Doe",
  "email": "john@example.com",
  "phone_number": "1234567890",
  "password": "hashed_password",
  "nominee_number": "9876543210"
}

Response:
{
  "id": 1,
  "message": "User registered with fingerprint"
}
```

## Setup Instructions

### 1. Database Setup
```bash
# Drop and recreate database with new schema
psql -U postgres -c "DROP DATABASE saveone_db;"
psql -U postgres -f backend/database.sql
```

### 2. Backend Setup
```bash
cd backend
npm start
# Server running on http://localhost:3000
```

### 3. ESP32 Setup
1. Install Arduino IDE
2. Install libraries: Adafruit Fingerprint, ArduinoJson
3. Open `hardware/fingerprint_esp32/fingerprint_esp32.ino`
4. Update WiFi credentials:
   ```cpp
   const char* ssid = "YourWiFiName";
   const char* password = "YourWiFiPassword";
   ```
5. Find your computer's IP address:
   - Mac/Linux: `ifconfig | grep inet`
   - Windows: `ipconfig`
6. Update server URL:
   ```cpp
   const char* serverUrl = "http://192.168.1.100:3000/api/fingerprint";
   ```
7. Upload to ESP32
8. Open Serial Monitor (115200 baud)

### 4. Flutter App Setup
```bash
flutter pub get
flutter run
```

## Testing the Flow

### Test 1: New User Registration
1. Place finger on ESP32 sensor (new fingerprint)
2. ESP32 enrolls it as ID=1
3. Note the ID from Serial Monitor
4. Open Flutter app → Sign Up with Fingerprint
5. Enter fingerprint ID: 1
6. Fill in user details
7. Submit
8. User is created and logged in

### Test 2: Existing User Login
1. Place registered finger on ESP32 sensor
2. ESP32 recognizes it (ID=1)
3. ESP32 calls backend
4. LED stays on for 2 seconds
5. Serial shows: "Welcome, John Doe"
6. (Optional) Open Flutter app and auto-login with fingerprint ID

## Troubleshooting

### ESP32 Issues
- **Sensor not detected**: Check wiring (RX→16, TX→17, VCC→3.3V, GND→GND)
- **WiFi not connecting**: Verify SSID/password, use 2.4GHz network
- **HTTP Error 404**: Check server URL and IP address
- **HTTP Error -1**: Backend not running or firewall blocking

### Backend Issues
- **Database error**: Run migration script or recreate database
- **CORS error**: Already configured in server.js
- **Port 3000 in use**: Change PORT in .env file

### Flutter App Issues
- **Connection refused**: Update baseUrl to computer's IP (not localhost)
- **Android emulator**: Use `10.0.2.2:3000` instead of `localhost:3000`

## Security Considerations

1. **Fingerprint ID is not encrypted** - It's just a number (1-127)
2. **Password should be hashed** - Use SHA-256 or bcrypt
3. **HTTPS recommended** - For production, use SSL/TLS
4. **Fingerprint spoofing** - Consider adding additional verification
5. **Network security** - Use VPN or secure WiFi

## Future Enhancements

- [ ] Add fingerprint enrollment directly from Flutter app
- [ ] Implement fingerprint deletion/update
- [ ] Add multi-factor authentication
- [ ] Encrypt communication between ESP32 and backend
- [ ] Add fingerprint quality check
- [ ] Implement fingerprint template backup
