# AI-Driven Smart Logistics Assistant (React Native Migration)

This project has been migrated from **Flutter** to **React Native (Expo)** to leverage a more extensive JS-based ecosystem while maintaining high performance and a premium look.

## 🚀 Overview
The Smart Logistics Assistant is a real-time route optimization platform designed for logistics in Sri Lanka. It uses traffic-aware AI processing to calculate the most efficient routes, saving fuel and time.

## 🛠 Tech Stack
*   **Mobile App**: React Native (Expo), Lucide Icons, React Native Maps
*   **Backend**: Python (Flask), Flask-SocketIO
*   **AI Engine**: Google Maps Distance Matrix API
*   **Real-time**: Socket.IO

## 📁 Project Structure
*   `react_native_app/`: The core React Native mobile application.
*   `backend/`: Python Flask server for route optimization and real-time streaming.
*   `mobile_app/`: Legacy Flutter implementation (for reference).

## 🚦 Getting Started

### 1. Backend (Flask)
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```
Create a `.env` file in the `backend/` directory with your `GOOGLE_MAPS_API_KEY`.

Run the server:
```bash
python app.py
```

### 2. Mobile App (React Native)
```bash
cd react_native_app
npm install
npx expo start
```

## 🎨 Features
*   **Real-time Traffic**: Ingests live data for Colombo areas.
*   **Fuel Optimization**: ML-based route calculation.
*   **Live Sync**: WebSockets stream coordinates directly to the map.
*   **Premium UI**: Glassmorphic components and smooth transitions.
