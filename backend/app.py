import os
import asyncio
from functools import wraps
from flask import Flask, request, jsonify
from flask_socketio import SocketIO, emit
from flask_cors import CORS
import googlemaps
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY')
if not app.config['SECRET_KEY'] or app.config['SECRET_KEY'] == 'replace_with_secure_random_key':
    raise ValueError(
        "SECRET_KEY is not configured. Set it in backend/.env or run: "
        "python -c \"import secrets; print(secrets.token_hex(32))\""
    )

app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max payload

# CORS configuration - restrict to specific origins in production
cors_origins = os.getenv('CORS_ALLOWED_ORIGINS', 'http://localhost:5000').split(',')
CORS(app, origins=cors_origins, supports_credentials=True)

socketio = SocketIO(app, cors_allowed_origins=cors_origins, async_mode='threading')

# Initialize Google Maps client (optional — runs with mock data if no key)
api_key = os.getenv('GOOGLE_MAPS_API_KEY')
gmaps = None
if api_key and api_key != 'your_google_maps_api_key_here':
    try:
        gmaps = googlemaps.Client(key=api_key)
        print("[OK] Google Maps API connected.")
    except Exception as e:
        print(f"[WARN] Failed to initialize Google Maps API: {e}")
        print("[WARN] Running with mock traffic data.")
else:
    print("[WARN] No Google Maps API key configured. Running with mock traffic data.")


def validate_json(required_fields: list):
    """Decorator to validate JSON request body."""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            data = request.get_json(silent=True)
            if data is None:
                return jsonify({'error': 'Invalid or missing JSON body'}), 400

            missing = [field for field in required_fields if field not in data]
            if missing:
                return jsonify({'error': f'Missing required fields: {", ".join(missing)}'}), 400

            return f(*args, **kwargs)
        return decorated_function
    return decorator


def async_sleep(seconds: float):
    """Non-blocking sleep for async operations."""
    return asyncio.sleep(seconds)


def get_realtime_traffic(origin: str, destination: str):
    """
    Fetches traffic data between origin and destination using Google Maps Distance Matrix.
    Returns mock data if Google Maps API is unavailable.
    """
    if gmaps is None:
        return None

    try:
        now = int(os.time.time())
        result = gmaps.distance_matrix(
            origin,
            destination,
            mode="driving",
            departure_time=now,
            traffic_model="best_guess"
        )
        return result
    except Exception as e:
        print(f"[ERROR] Error fetching traffic data: {e}")
        return None


def optimize_route(data: dict) -> dict:
    """
    Route optimization with traffic-aware calculation.
    Uses mock data when Google Maps API is unavailable.
    """
    # Validate input data
    origin = data.get('origin', 'Colombo Fort')
    destination = data.get('destination', 'Kollupitiya')

    # Check if we have valid traffic data
    traffic_data = get_realtime_traffic(origin, destination)

    # Define route waypoints for Colombo area
    base_route = [
        {"lat": 6.9271, "lng": 79.8612, "label": "Colombo Fort (Start)"},
        {"lat": 6.9280, "lng": 79.8550, "label": "Pettah Junction"},
        {"lat": 6.9300, "lng": 79.8480, "label": "Port City Bypass"},
        {"lat": 6.9319, "lng": 79.8430, "label": "Kollupitiya (End)"}
    ]

    # Adjust estimated time based on traffic (mock logic)
    if traffic_data:
        try:
            element = traffic_data['rows'][0]['elements'][0]
            if element['status'] == 'OK':
                duration = element['duration']['text']
                duration_text = element['duration_in_traffic']['text']
                return {
                    "status": "success",
                    "optimized_route": base_route,
                    "traffic_info": {
                        "duration": duration,
                        "duration_in_traffic": duration_text,
                        "status": element['status']
                    },
                    "fuel_saved": "15%",
                    "estimated_time": duration_text
                }
        except (IndexError, KeyError) as e:
            print(f"[WARN] Could not parse traffic response: {e}")

    # Return mock data with default values when API unavailable
    return {
        "status": "success",
        "optimized_route": base_route,
        "traffic_info": {
            "duration": "20 mins",
            "status": "mock_data"
        },
        "fuel_saved": "12%",
        "estimated_time": "20 mins"
    }


@app.route('/api/optimize', methods=['POST'])
@validate_json(['origin', 'destination'])
def handle_optimization_request():
    """Handle route optimization requests with input validation."""
    try:
        data = request.get_json()
        result = optimize_route(data)
        return jsonify(result), 200
    except Exception as e:
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500


@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint."""
    status = {
        'status': 'healthy',
        'google_maps': 'connected' if gmaps else 'using_mock_data',
        'service': 'AI-Driven Smart Logistics Assistant'
    }
    return jsonify(status), 200


@socketio.on('connect')
def handle_connect():
    """Handle new WebSocket connections."""
    print("[SOCKET] Client connected")


@socketio.on('disconnect')
def handle_disconnect():
    """Handle WebSocket disconnections."""
    print("[SOCKET] Client disconnected")


@socketio.on('request_route_sync')
def handle_route_sync(data: dict):
    """
    Handles real-time route synchronization requests via WebSockets.
    Emits route coordinates with labels for map visualization.
    """
    route_id = data.get('route_id', 'unknown_route')
    print(f"[SOCKET] Received sync request: {route_id}")

    # Define route steps for Colombo
    steps = [
        {"lat": 6.9271, "lng": 79.8612, "label": "Colombo Fort (Start)"},
        {"lat": 6.9280, "lng": 79.8550, "label": "Pettah Junction"},
        {"lat": 6.9300, "lng": 79.8480, "label": "Port City Bypass"},
        {"lat": 6.9319, "lng": 79.8430, "label": "Kollupitiya (End)"}
    ]

    try:
        for step in steps:
            # Use async sleep instead of blocking sleep
            import asyncio
            asyncio.run(asyncio.sleep(0.5))  # Reduced delay for faster streaming
            emit('route_update', step, namespace='/')

        emit('route_complete', {"total_steps": len(steps), "route_id": route_id}, namespace='/')
        print(f"[SOCKET] Route sync complete: {route_id}")
    except Exception as e:
        print(f"[SOCKET] Error during sync: {e}")
        emit('route_error', {'error': str(e)}, namespace='/')


if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('FLASK_ENV') == 'development'

    print(f"[START] Starting server on port {port}")
    print(f"[START] Environment: {'development' if debug else 'production'}")

    socketio.run(app, debug=debug, port=port, allow_unsafe_werkzeug=True)
