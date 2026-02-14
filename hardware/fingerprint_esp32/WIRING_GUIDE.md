# ESP32 Wiring Guide - Complete System

## Components
- ESP32 Development Board
- R307 Fingerprint Sensor
- NEO-6M GPS Module
- SIM800L GSM Module
- Battery (3.7V LiPo recommended)

## Wiring Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         ESP32                                │
│                                                              │
│  3.3V ────┬────┬────┐                                       │
│           │    │    │                                       │
│  GND ─────┼────┼────┼────┐                                 │
│           │    │    │    │                                 │
│  GPIO16 ──┼────┼────┼────┼─── RX1 (Fingerprint)           │
│  GPIO17 ──┼────┼────┼────┼─── TX1 (Fingerprint)           │
│           │    │    │    │                                 │
│  GPIO4  ──┼────┼────┼────┼─── RX2 (GPS)                   │
│  GPIO2  ──┼────┼────┼────┼─── TX2 (GPS)                   │
│           │    │    │    │                                 │
│  GPIO3  ──┼────┼────┼────┼─── RX0 (GSM)                   │
│  GPIO1  ──┼────┼────┼────┼─── TX0 (GSM)                   │
│           │    │    │    │                                 │
│  VIN ─────┼────┼────┼────┼─── Battery + (3.7V-4.2V)       │
└───────────┼────┼────┼────┼─────────────────────────────────┘
            │    │    │    │
            ↓    ↓    ↓    ↓

┌───────────────────┐  ┌──────────────┐  ┌──────────────┐
│  R307 Fingerprint │  │   NEO-6M GPS │  │  SIM800L GSM │
├───────────────────┤  ├──────────────┤  ├──────────────┤
│ VCC → 3.3V        │  │ VCC → 3.3V   │  │ VCC → 4.2V   │
│ GND → GND         │  │ GND → GND    │  │ GND → GND    │
│ TX  → GPIO16      │  │ TX  → GPIO4  │  │ TX  → GPIO3  │
│ RX  → GPIO17      │  │ RX  → GPIO2  │  │ RX  → GPIO1  │
└───────────────────┘  └──────────────┘  └──────────────┘

Battery Connection:
┌──────────────┐
│  3.7V LiPo   │
│   Battery    │
├──────────────┤
│  +  → VIN    │
│  -  → GND    │
└──────────────┘
```

## Detailed Pin Connections

### R307 Fingerprint Sensor
| Sensor Pin | Wire Color | ESP32 Pin | Notes              |
|------------|------------|-----------|-------------------|
| VCC        | Red        | 3.3V      | Power supply      |
| GND        | Black      | GND       | Ground            |
| TX         | White      | GPIO16    | Sensor to ESP32   |
| RX         | Green      | GPIO17    | ESP32 to Sensor   |

### NEO-6M GPS Module
| GPS Pin    | ESP32 Pin | Notes              |
|------------|-----------|-------------------|
| VCC        | 3.3V      | Power supply      |
| GND        | GND       | Ground            |
| TX         | GPIO4     | GPS to ESP32      |
| RX         | GPIO2     | ESP32 to GPS      |

### SIM800L GSM Module
| GSM Pin    | ESP32 Pin | Notes                    |
|------------|-----------|--------------------------|
| VCC        | VIN       | Needs 3.7V-4.2V         |
| GND        | GND       | Ground                   |
| TX         | GPIO3     | GSM to ESP32 (RX0)      |
| RX         | GPIO1     | ESP32 to GSM (TX0)      |

### Battery
| Battery    | ESP32 Pin | Notes                    |
|------------|-----------|--------------------------|
| + (Positive)| VIN      | 3.7V-4.2V LiPo          |
| - (Negative)| GND      | Ground                   |

## Important Notes

### Power Requirements
- **R307 Fingerprint**: 3.3V, ~120mA (peak)
- **NEO-6M GPS**: 3.3V, ~50mA
- **SIM800L GSM**: 3.7V-4.2V, ~2A (peak during transmission)
- **ESP32**: 3.3V, ~240mA (WiFi active)

### Critical: SIM800L Power
⚠️ **SIM800L requires 3.7V-4.2V and high current (up to 2A)**
- Connect directly to battery or use voltage regulator
- DO NOT power from ESP32 3.3V pin (insufficient current)
- Use thick wires for SIM800L power connections
- Add 100-1000µF capacitor near SIM800L VCC/GND

### Battery Recommendations
- **3.7V LiPo battery** (1000mAh minimum, 2000mAh+ recommended)
- Use battery protection circuit (BMS)
- Consider TP4056 charging module for USB charging

### Serial Port Usage
- **Serial0 (GPIO1/3)**: GSM communication
- **Serial1 (GPIO16/17)**: Fingerprint sensor
- **Serial2 (GPIO4/2)**: GPS module

## Assembly Steps

1. **Prepare ESP32**
   - Connect battery to VIN and GND
   - Test power LED lights up

2. **Connect Fingerprint Sensor**
   - VCC to 3.3V
   - GND to GND
   - TX to GPIO16
   - RX to GPIO17

3. **Connect GPS Module**
   - VCC to 3.3V
   - GND to GND
   - TX to GPIO4
   - RX to GPIO2

4. **Connect GSM Module**
   - VCC to VIN (battery voltage)
   - GND to GND
   - TX to GPIO3
   - RX to GPIO1
   - Add capacitor near VCC/GND

5. **Insert SIM Card**
   - Power off system
   - Insert activated SIM card into SIM800L
   - Ensure SIM has credit for SMS

6. **Test System**
   - Upload code to ESP32
   - Open Serial Monitor (9600 baud)
   - Check initialization messages

## Troubleshooting

### Fingerprint Sensor Issues
- **Not detected**: Check RX/TX connections (swap if needed)
- **No response**: Verify 3.3V power supply
- **Red light blinking**: Normal, waiting for finger

### GPS Issues
- **No fix**: Place near window or outdoors
- **No data**: Check RX/TX connections
- **Slow fix**: First fix takes 30-60 seconds

### GSM Issues
- **No response**: Check power supply (needs 3.7V-4.2V)
- **Resets during SMS**: Add capacitor, use thicker wires
- **No network**: Check SIM card, antenna, signal strength
- **AT commands fail**: Check baud rate (9600)

### Power Issues
- **System resets**: SIM800L drawing too much current
  - Solution: Add large capacitor (1000µF)
  - Use separate power supply for SIM800L
- **Battery drains fast**: Normal, GSM uses high power
  - Use 2000mAh+ battery
  - Implement sleep mode

## Safety Warnings

⚠️ **DO NOT:**
- Short circuit battery terminals
- Reverse polarity connections
- Power SIM800L from 3.3V pin
- Use battery without protection circuit
- Leave system unattended while charging

✅ **DO:**
- Double-check all connections before powering on
- Use proper gauge wires (20-22 AWG)
- Add capacitors for stable power
- Test each module individually first
- Use battery with BMS protection
