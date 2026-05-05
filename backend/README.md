# Backend Flask API for AI-Driven Smart Logistics Assistant

## Quick Start

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your Google Maps API key
```

## Running the Server

```bash
python app.py
```

The server runs on `http://localhost:5000` by default.

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `GOOGLE_MAPS_API_KEY` | Your Google Maps API key | `AIzaSy...` |
| `SECRET_KEY` | Flask secret key (32 hex chars) | `python -c "import secrets; print(secrets.token_hex(32))"` |
| `CORS_ALLOWED_ORIGINS` | Allowed origins (comma-separated) | `http://localhost:3000,http://localhost:8080` |
| `PORT` | Server port (default: 5000) | `5000` |
| `FLASK_ENV` | Environment (development/production) | `development` |

## API Endpoints

### POST `/api/optimize`
Optimize a delivery route between two locations.

**Request Body:**
```json
{
  "origin": "Colombo Fort",
  "destination": "Kollupitiya"
}
```

**Response:**
```json
{
  "status": "success",
  "optimized_route": [
    {"lat": 6.9271, "lng": 79.8612, "label": "Colombo Fort (Start)"},
    ...
  ],
  "traffic_info": {
    "duration": "20 mins",
    "status": "OK"
  },
  "fuel_saved": "15%",
  "estimated_time": "20 mins"
}
```

### GET `/api/health`
Health check endpoint.

## WebSocket Events

### Client → Server
- `request_route_sync`: Request real-time route streaming with `{"route_id": "unique_id"}`

### Server → Client
- `route_update`: Route waypoint with `{"lat", "lng", "label"}`
- `route_complete`: `{"total_steps": N, "route_id": "..."}`
- `route_error`: `{"error": "message"}`

## Security Notes

- Never commit `.env` to version control
- Use strong `SECRET_KEY` values in production
- Configure `CORS_ALLOWED_ORIGINS` for your production domains
