# Connectivity Sensor App

## 1. Project Overview

Connectivity Sensor App is a Flutter application for collecting, monitoring, and storing multimodal sensor data from external hardware.

The project is built for scenarios where multiple sensors work together to capture speech-related and environmental signals. The app supports live monitoring, per-sensor collection control, local persistence, and transport over Wi-Fi or USB.

The current app is focused on these sensors:

- Piezoelectric vibration sensor
- MEMS microphone
- Airflow sensor
- Pressure sensor
- IMU
- Temperature and humidity sensor

The app provides a user-facing interface to:

- view the list of supported sensors
- inspect each sensor's purpose and features
- enable or disable individual sensor collection
- connect to a real sensor hub
- monitor incoming sensor values in real time
- store collected samples locally

## 2. Main Goal of the Project

The main goal of the project is to act as a real-time data collection app for external sensors used in multimodal sensing workflows.

The app should be able to:

- receive live readings from real hardware
- display the incoming data clearly
- keep track of active data collection sessions
- store collected readings safely
- later sync or upload the data to a backend

## 3. Current Technology Stack

### Frontend / App

- Flutter
- Provider for state management
- Hive for local storage
- fl_chart for data visualization

### Native Integration

- Android USB host integration through `MethodChannel` and `EventChannel`
- TCP socket ingestion for Wi-Fi connected sensor hubs

## 4. Project Structure

### Main App Files

- `lib/main.dart`
  - application entry point
  - initializes storage
  - injects monitoring state

- `lib/providers/monitoring_provider.dart`
  - central state manager
  - starts and stops collection
  - handles incoming readings
  - manages enabled sensors
  - triggers storage

- `lib/models/sensor_data.dart`
  - unified data model for all readings
  - supports transport parsing and local persistence mapping

- `lib/models/sensor_connection_config.dart`
  - stores connection mode and configuration

- `lib/services/live_sensor_stream_service.dart`
  - handles real input over Wi-Fi and USB

- `lib/services/storage_service.dart`
  - handles local storage
  - contains stub for cloud storage

- `lib/screens/dashboard_screen.dart`
  - live monitoring dashboard
  - connection settings
  - charts and live values

- `lib/screens/sensor_list_screen.dart`
  - sensor selection and sensor overview

### Native Android Files

- `android/app/src/main/kotlin/com/connectivity/connectivity_sensor_app/MainActivity.kt`
  - USB host integration
  - permission handling
  - USB packet read loop

- `android/app/src/main/AndroidManifest.xml`
  - internet permission
  - USB host feature declaration

## 5. Sensors Covered by the App

The sensor definitions are currently described in `assets/sensors.json`.

The supported sensors are:

### Piezoelectric Vibration Sensor

- captures throat or chest vibration
- used for vibration RMS and related vibration-based speech cues

### MEMS Microphone

- captures acoustic information
- currently represented in the app as microphone level

### Airflow Sensor

- measures airflow near the mouth or nose
- used for speech onset and airflow activity

### Pressure Sensor

- measures differential pressure
- supports speech-related pressure analysis

### IMU

- tracks motion along X, Y, Z axes
- useful for head, neck, or jaw motion sensing

### Temperature and Humidity Sensor

- captures environmental conditions
- useful for calibration and normalization

## 6. How Data Flows Through the App

The current data flow is:

1. Physical sensors send their signals to the microcontroller or sensor hub.
2. Firmware, such as STM32 firmware written in STM32CubeIDE, reads the sensor values from ADC, I2C, SPI, UART, or any other sensor interface used by the hardware.
3. The firmware sends packets out over Wi-Fi TCP or USB.
4. The app receives newline-framed packets. One packet must end with `\n` so the app can tell where one reading ends and the next one begins.
5. The transport service preserves each full packet as raw transport data.
6. If the packet is a JSON object, the app also parses chart-friendly fields into `SensorData`.
7. If the packet is plain text, CSV, or binary bytes, the app still stores it losslessly as raw data for later decoding or backend processing.
8. `MonitoringProvider` updates:
   - latest reading
   - historical chart data when numeric fields are available
   - session counters
   - active stream statistics
9. The reading and raw transport payload are saved locally in Hive.
10. The same saved data can later be sent to cloud storage when backend integration is added.

The important design rule is that the app now captures raw data first and only parses it when it knows how. This avoids losing sensor details just because the firmware sends a format other than JSON.

## 7. Real Sensor Connectivity

The app now supports three modes:

### Wi-Fi Mode

- connects to a sensor hub through TCP
- user enters host/IP and port
- sensor packets are read as bytes and split by newline framing
- supports JSON, text, CSV, or binary packet contents

### USB Mode

- available on Android
- uses USB host mode
- listens to a connected USB device and reads incoming byte packets
- uses Android's built-in USB host APIs, not STM32CubeIDE, ST-LINK, or vendor-specific desktop drivers
- forwards packet bytes to Flutter instead of forcing the USB stream to UTF-8 text too early
- supports JSON, text, CSV, or binary packet contents after newline framing

### Mock Mode

- used for UI testing and demo mode
- helpful when hardware is not connected

## 8. Packet Format Supported by the App

The app expects one packet per line. The packet can contain JSON, plain text, CSV, or binary bytes.

The only fixed requirement is framing:

- each packet must end with newline `\n`
- newline separates packets over both Wi-Fi and USB
- the packet content before the newline can be text or bytes

JSON objects are parsed into chart-friendly fields. Non-JSON packets are not rejected; they are stored as raw transport payloads.

### JSON Packets

```json
{"timestamp":"2026-04-08T10:15:00Z","temperature":27.1,"humidity":51.2,"airflow":3.9,"pressure":112.0,"vibrationRms":0.63,"microphoneLevel":68.4,"imuX":0.12,"imuY":-0.07,"imuZ":0.98}
```

Accepted alternate keys include:

- `temp`, `temp_c`
- `rh`, `humidity_percent`
- `flow`, `airflow_mps`
- `pressure_pa`
- `piezo_rms`
- `mic_db`, `mic_level`
- `accel_x`, `ax`
- `accel_y`, `ay`
- `accel_z`, `az`

When packets use these fields, the dashboard can show live values and charts.

### Plain Text or CSV Packets

The firmware can also send plain text or CSV. For example:

```text
27.1,51.2,3.9,112.0,0.63,68.4,0.12,-0.07,0.98
```

The app stores this as raw text. It does not currently infer CSV column meanings automatically, so chart fields will remain zero unless a parser is added later.

### Binary Packets

The firmware can send binary bytes as long as packets are newline-framed. If the packet is not valid UTF-8 text, the app stores the bytes as Base64 in `rawBytesBase64`.

This allows the app to preserve raw microphone samples, ADC buffers, compact binary frames, or other custom firmware payloads without throwing the packet away. A backend or future decoder can later convert the Base64 data back into the original bytes.

### STM32CubeIDE Relationship

STM32CubeIDE is used to write and flash the STM32 firmware. The app does not connect directly to CubeIDE or ST-LINK debug sessions.

The supported flow is:

```text
Sensors -> STM32 firmware built in CubeIDE -> Wi-Fi TCP or USB -> Flutter app -> local storage -> future backend
```

This means CubeIDE-associated sensors can work with the app when the STM32 firmware streams packets over Wi-Fi or USB. The firmware decides the packet format. The app can preserve JSON, text, CSV, or binary payloads, but the firmware still needs to send clear packet boundaries using newline framing.

### Current Limits

- live charts only update automatically from known JSON fields
- text, CSV, and binary packets are preserved losslessly but not fully interpreted into chart fields yet
- USB support uses the first readable bulk or interrupt IN endpoint found on Android
- USB CDC serial devices may need more specific CDC ACM handling for production reliability
- ST-LINK, CubeIDE debug connections, and desktop driver connections are not supported by this mobile app

## 9. Current Functionalities in the App

The app currently supports these user-facing capabilities:

- sensor list screen
- detailed sensor information screen
- per-sensor enable/disable controls
- dashboard for live monitoring
- vibration, airflow, and IMU charts
- connection configuration for Wi-Fi, USB, or mock mode
- live reading display for all major sensor fields
- session counters for frames and active streams
- local storage toggle
- cloud storage toggle placeholder
- locally persisted samples through Hive
- raw transport payload preservation for lossless JSON, text, CSV, and binary packet storage

## 10. What the Backend Should Do

The app already collects and stores data locally, but a proper backend is still needed.

The backend should support:

### Authentication and Users

- user registration and login
- user roles if multiple operators or researchers use the system

### Device Registration

- register sensor hubs
- track device IDs, firmware versions, and ownership

### Session Management

- create a collection session
- stop a collection session
- attach metadata to the session
- track which sensors were active during the session

### Cloud Data Ingestion

- receive sensor data from the app, including the preserved raw transport payload when lossless storage is required
- support both single-reading and batch upload
- validate packet schema without discarding raw fields needed for later reprocessing
- store `rawFormat`, `rawPacket`, `rawBytesBase64`, and parsed sensor fields when present
- decode or post-process text, CSV, and binary packets when the backend knows the device-specific format
- keep original raw payloads even after successful decoding so reprocessing is possible later

### Data Storage

- store time-series sensor data efficiently
- store session metadata
- support querying by user, session, device, date, and sensor type

### Sync for Offline Data

- allow local data collected offline to be uploaded later
- prevent duplicates
- mark sync success/failure

### Real-Time Monitoring

- provide APIs or WebSockets for live viewing
- support monitoring dashboards

### Export and Dataset Tools

- export CSV or JSON
- support dataset grouping
- attach labels or annotations

### Health and Audit

- track device online/offline state
- detect missing packets
- maintain logs for ingestion and errors

## 11. Recommended Backend Components

A practical backend architecture could include:

- REST API or GraphQL API
- WebSocket support for live monitoring
- PostgreSQL for metadata and sessions
- TimescaleDB or InfluxDB for time-series data
- object storage for exports and logs
- authentication using JWT, Firebase Auth, or Auth0

## 12. Recommended API Endpoints

Examples of useful backend endpoints:

- `POST /auth/login`
- `POST /devices/register`
- `POST /sessions/start`
- `POST /sessions/{id}/ingest`
- `POST /sessions/{id}/end`
- `GET /sessions`
- `GET /sessions/{id}`
- `GET /sessions/{id}/data`
- `GET /devices`
- `GET /exports/{sessionId}`
- WebSocket endpoint for live monitoring

## 13. What Is Done

The following has already been implemented:

- Flutter app UI for sensor overview and dashboard
- sensor metadata loading from JSON
- per-sensor collection toggles
- live values and chart-based monitoring
- local persistence using Hive
- unified sensor data model with parsed fields and preserved raw transport payloads
- real Wi-Fi ingestion using TCP sockets
- real USB ingestion on Android using native USB host integration
- raw byte packet handling before JSON/text/binary detection
- lossless storage support for JSON, text, CSV, and binary packet contents
- dashboard display for raw format, raw transport payload, original packet text, and Base64 binary bytes
- connection configuration in the UI
- basic error state handling for connection issues
- git integration and commit for the recent real-sensor update

## 14. What Still Needs To Be Done

The following work is still pending:

### Backend Integration

- replace cloud storage stub with real backend upload
- create APIs for sessions, uploads, and retrieval
- implement authentication

### Data Management

- session naming and labeling
- session history screen
- export features
- search and filtering for stored data

### Hardware Integration Improvements

- align the app packet parser with the exact firmware payload format
- add optional CSV-to-field mapping if CSV packets need live charts
- add optional binary decoders for device-specific raw microphone, ADC, or IMU frames
- support richer microphone payloads if required
- handle more detailed IMU data if gyroscope values are needed separately
- improve USB device selection when multiple USB devices are connected
- add stronger USB CDC ACM support if the STM32 presents itself as a virtual COM port

### Reliability

- retry logic for network failures
- better buffering and reconnection strategy
- upload queue for offline-to-online synchronization

### Platform Coverage

- iOS hardware support if needed
- desktop support if required
- web support if desired

### Security and Production Readiness

- secure cloud sync
- device identity verification
- audit trails
- data encryption strategy if sensitive data is collected

## 15. Final Summary

This project has moved beyond a mock-only Flutter prototype and is now capable of receiving real sensor data over Wi-Fi and USB, displaying it live when fields can be parsed, and storing the original raw packet locally.

What is complete:

- sensor UI
- real-time monitoring UI
- sensor selection workflow
- Wi-Fi ingestion
- Android USB ingestion
- local storage
- unified transport parsing
- raw packet preservation for JSON, text, CSV, and binary payloads
- JSON field parsing for dashboard charts and live values
- raw binary packet storage as Base64

What is not complete yet:

- production backend
- real cloud sync
- full session management
- export and analytics workflows
- exact firmware-to-app protocol finalization
- automatic live chart parsing for CSV or custom binary packet formats
- production-grade USB serial/CDC handling if the target STM32 board requires it

In short, the app is now a working real-sensor collection frontend that can preserve raw packets from STM32/CubeIDE firmware over Wi-Fi or USB. The backend and production data pipeline still need to be built to make the system complete end to end.
