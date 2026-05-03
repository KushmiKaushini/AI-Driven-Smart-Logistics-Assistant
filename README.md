# AI-Driven Smart Logistics Assistant (Sri Lanka)

This project optimizes delivery routes in Colombo using real-time traffic data and ML.

## Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Python 3.10+](https://www.python.org/downloads/)
- Google Maps API Key (with Distance Matrix and Maps SDK enabled)

## Setup Instructions

### 1. Backend (Flask)
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```
Create a `.env` file in the `backend/` directory:
```env
GOOGLE_MAPS_API_KEY=your_api_key_here
SECRET_KEY=your_secret_key
```
Run the server:
```bash
python app.py
```

### 2. Mobile App (Flutter)
```bash
cd mobile_app
flutter pub get
```
**Note**: You must configure your Google Maps API key in:
- Android: `android/app/src/main/AndroidManifest.xml`
- iOS: `ios/Runner/AppDelegate.swift`

Run the app:
```bash
flutter run
```

## Features
- **Real-time Traffic**: Ingests live data for Colombo areas.
- **Fuel Optimization**: ML-based route calculation.
- **Live Sync**: WebSockets stream coordinates directly to the map.
