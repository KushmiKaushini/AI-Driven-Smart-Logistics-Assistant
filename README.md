# AI-Driven Smart Logistics Assistant 🚚

A premium, real-time route optimization platform for logistics operations in Colombo, Sri Lanka. This project features a state-of-the-art **React Native** frontend integrated with a traffic-aware **Flask** backend.

---

## 🌟 Key Features
*   **Real-Time Route Streaming**: Live coordinate synchronization via Socket.IO.
*   **AI-Powered Optimization**: Traffic-aware routing using Google Maps Distance Matrix.
*   **Premium Glassmorphism UI**: High-fidelity interface with frosted-glass effects and Lucide icons.
*   **High Performance**: React Native optimized with `useMemo` for smooth map interactions.
*   **Fuel Efficiency**: Real-time fuel saving estimations based on traffic density.

---

## 🛠 Technology Stack

### Frontend (Mobile)
*   **Framework**: React Native (Expo)
*   **Maps**: React Native Maps (Google Maps Provider)
*   **Real-time**: Socket.IO Client
*   **Styling**: Expo Blur (Glassmorphism), Lucide Icons

### Backend (API)
*   **Framework**: Flask (Python 3.10+)
*   **Real-time**: Flask-SocketIO
*   **Geospatial**: Google Maps Python Client

---

## 📂 Project Architecture

The project follows a professional, decoupled architecture for scalability:

```
/react_native_app
  ├── /src
  │    ├── /components    # Glassmorphic UI & reusable elements
  │    ├── /screens       # MapScreen & Logistics Dashboard
  │    ├── /services      # Axios API & Socket.IO initialization
  │    ├── /hooks         # Real-time synchronization logic
  │    ├── /theme         # Centralized color tokens
  │    └── /constants     # Map styles & app configurations
  └── App.js              # Clean entry point
/backend
  ├── app.py              # Flask server & SocketIO logic
  └── .env                # API Keys & Secrets
/mobile_app               # Legacy Flutter implementation
```

---

## 🚦 Getting Started

### 1. Prerequisites
*   Node.js & npm
*   Python 3.10+
*   Google Maps API Key (Distance Matrix & Maps SDK enabled)

### 2. Backend Setup
```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
```
Configure your `.env` file:
```env
GOOGLE_MAPS_API_KEY=your_api_key_here
SECRET_KEY=your_secure_random_key
```
Run the server:
```bash
python app.py
```

### 3. Mobile App Setup (React Native)
```bash
cd react_native_app
npm install
```
Configure your Google Maps API key in `react_native_app/app.json`:
```json
"android": {
  "config": {
    "googleMaps": {
      "apiKey": "YOUR_KEY_HERE"
    }
  }
}
```
Run the application:
```bash
npx expo start
```

---

## 🛡 Security & Audit
The codebase has undergone a full security audit. Vulnerabilities in sub-dependencies (like `postcss`) have been resolved using npm overrides in the `package.json` to ensure a secure, production-ready environment.

---

## 📝 License
MIT License. Developed for Advanced Smart Logistics.
