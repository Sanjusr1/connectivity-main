# Connectivity Sensor App

This project is a real-time data collection and monitoring system for external hardware sensors. It consists of a **FastAPI python backend** and a **Flutter frontend** (supporting Web, Android, and other native platforms).

---

## 1. Quick Setup & Run Commands

### A. Run Backend & Mock Telemetry Hubs
Navigate to the `backend` folder, activate the virtual environment, and run the server/mock streams:

1. **Activate Environment**:
   ```powershell
   cd backend
   .\.venv\Scripts\Activate.ps1
   ```
2. **Run Backend API Server (Port 8000)**:
   ```powershell
   python -m uvicorn app.main:app --reload
   ```
3. **Run Mock TCP Server (Port 9000 - For Native App testing)**:
   ```powershell
   python run_mock_tcp.py
   ```
4. **Run Mock WebSocket Server (Port 8080 - For Web App testing)**:
   ```powershell
   python run_mock_websocket.py
   ```

---

### B. Run or Deploy Frontend (Web App)
From the project root directory:

* **Run Web App locally (Port 8081)**:
   ```powershell
   python -m http.server 8081 --directory build/web
   ```
* **Build Web Assets**:
   ```powershell
   flutter build web
   ```
* **Deploy to Surge (HTTP / Insecure)**:
   ```powershell
   npx surge build/web connectivity-sensor-app-2026.surge.sh
   ```
* **Deploy to Firebase (HTTPS / Secure)**:
   ```powershell
   npx firebase-tools deploy --only hosting
   ```

---

### C. Build Native Android App
From the project root directory:
```powershell
flutter build apk --debug
```
*The generated APK will be stored at: `build/app/outputs/flutter-apk/app-debug.apk`.*

---

## 2. Ingestion Settings & Testing
* **Web App Ingestion**: Select **Wi-Fi**, enter host `ws://<your-laptop-ip>` and port `8080` (WebSocket).
* **Android Ingestion**: Select **Wi-Fi**, enter host `<your-laptop-ip>` and port `9000` (Raw TCP).
* **Streaming over USB Cable (ADB Reverse)**: 
  Connect phone via USB (with debugging enabled) and run:
  ```powershell
  adb reverse tcp:9000 tcp:9000
  ```
  Then connect the Android app to Host `127.0.0.1` and Port `9000` (Wi-Fi mode).
