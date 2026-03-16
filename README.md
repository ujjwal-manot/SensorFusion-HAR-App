# SensorFusion HAR - Real-time Human Activity Recognition

Three-tier commercial HAR system: Flutter mobile app + FastAPI backend + React admin dashboard.

## Architecture

```
Phone (Flutter App)          Server (FastAPI)           Admin (React Dashboard)
┌─────────────────┐    WS    ┌──────────────────┐   WS   ┌──────────────────┐
│ Sensors (50Hz)  │ ──────→  │ WebSocket Hub    │ ────→  │ Live Feed View   │
│ TFLite Model    │          │ SQLite DB        │        │ User List        │
│ Activity Display│  REST    │ JWT Auth         │  REST  │ History Charts   │
│ History Sync    │ ──────→  │ REST API         │ ────→  │ Sensor Plots     │
└─────────────────┘          └──────────────────┘        └──────────────────┘
```

## Quick Start

### 1. Start Backend
```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
Admin account auto-created: `admin@har.app` / `admin123`

### 2. Start Admin Dashboard
```bash
cd dashboard
npm install
npm run dev
```
Open http://localhost:5173 and login with admin credentials.

### 3. Run Mobile App
Open `mobile/` in Android Studio or VS Code with Flutter extension.
```bash
cd mobile
flutter pub get
flutter run
```
In the app Settings, set the server URL to your laptop's IP (e.g., `http://192.168.1.5:8000`).

### 4. Generate Dummy Model (for testing)
```bash
cd model
pip install tensorflow
python generate_dummy_model.py
```
Copy `cascade_har_macro.tflite` to `mobile/assets/models/`.

## Finding Your Laptop IP
```bash
# Windows
ipconfig | findstr "IPv4"

# Mac/Linux
ifconfig | grep "inet "
```
Phone and laptop must be on the same WiFi network.

## Remote Testing (Without Same WiFi)
```bash
# Install ngrok
ngrok http 8000
# Use the ngrok URL in the Flutter app settings
```

## Project Structure
```
SensorFusion-HAR-App/
├── backend/          # FastAPI server (Python)
│   ├── app/
│   │   ├── main.py           # App entry, startup, CORS
│   │   ├── config.py         # Settings (env vars)
│   │   ├── database.py       # Async SQLAlchemy + SQLite
│   │   ├── models/           # SQLAlchemy models
│   │   ├── schemas/          # Pydantic schemas
│   │   ├── routers/          # API endpoints + WebSocket
│   │   ├── services/         # Business logic
│   │   └── middleware/       # Auth middleware
│   └── tests/
├── mobile/           # Flutter app (Dart)
│   ├── lib/
│   │   ├── config/           # App config, activity labels
│   │   ├── models/           # Data classes
│   │   ├── services/         # Sensor, inference, WS, sync, auth
│   │   ├── providers/        # Riverpod state management
│   │   ├── screens/          # Login, Home, History, Settings
│   │   └── widgets/          # Activity card, sensor chart, gauge
│   └── assets/
│       ├── models/           # TFLite model file
│       └── config/           # Activity labels JSON
├── dashboard/        # React admin dashboard (TypeScript)
│   └── src/
│       ├── api/              # Axios client, auth, users
│       ├── hooks/            # useAuth, useWebSocket
│       ├── pages/            # Login, Dashboard, UserDetail
│       ├── components/       # UserList, LivePanel, Charts
│       └── types/            # TypeScript interfaces
└── model/            # Model export scripts
    ├── activity_labels.json
    ├── export_tflite.py
    └── generate_dummy_model.py
```

## API Endpoints
| Method | Path | Description |
|--------|------|-------------|
| POST | /auth/register | Register new user |
| POST | /auth/login | Login, get JWT |
| GET | /auth/me | Current user info |
| POST | /activities/sync | Batch sync activity logs |
| GET | /activities/history | User's activity history |
| GET | /admin/users | All users + online status |
| GET | /admin/users/{id}/history | Specific user's history |
| WS | /ws/stream?token=JWT | Phone streams activity data |
| WS | /ws/admin/{user_id}?token=JWT | Admin watches user's live feed |
