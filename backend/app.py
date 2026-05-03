import os
import time
from flask import Flask, request, jsonify
from flask_socketio import SocketIO, emit
import googlemaps
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'secret!')
socketio = SocketIO(app, cors_allowed_origins="*")

# Initialize Google Maps client (optional — runs with mock data if no key)
api_key = os.getenv('GOOGLE_MAPS_API_KEY', '')
gmaps = None
if api_key and api_key != 'YOUR_GOOGLE_MAPS_API_KEY_HERE':
    try:
        gmaps = googlemaps.Client(key=api_key)
        print("[OK] Google Maps API connected.")
    except ValueError:
        print("[WARN] Invalid Google Maps API key. Running with mock traffic data.")
else:
    print("[WARN] No Google Maps API key set. Running with mock traffic data.")

def get_realtime_traffic(origin, destination):
    """
    Fetches traffic data between origin and destination using Google Maps Distance Matrix.
    """
    try:
        now = time.time()
        result = gmaps.distance_matrix(
            origin, 
            destination, 
            mode="driving", 
            departure_time=now, 
            traffic_model="best_guess"
        )
        return result
    except Exception as e:
        print(f"Error fetching traffic data: {e}")
        return None

def optimize_route(data):
    """
    Mock ML Model for route optimization.
    In a real scenario, this would use a trained model or a sophisticated algorithm (like A* or GA)
    considering fuel efficiency, vehicle type, and real-time traffic.
    """
    # Simulate processing time
    time.sleep(1)
    
    # Placeholder: Just return the coordinates with a 'fuel_efficiency' score
    optimized_path = [
        {"lat": 6.9271, "lng": 79.8612, "label": "Colombo Fort"},
        {"lat": 6.9319, "lng": 79.8430, "label": "Port City"},
        {"lat": 6.9044, "lng": 79.8540, "label": "Kollupitiya"}
    ]
    return {
        "status": "success",
        "optimized_route": optimized_path,
        "fuel_saved": "15%",
        "estimated_time": "25 mins"
    }

@app.route('/api/optimize', methods=['POST'])
def handle_optimization_request():
    data = request.json
    result = optimize_route(data)
    return jsonify(result)

@socketio.on('request_route_sync')
def handle_route_sync(data):
    """
    Handles real-time route synchronization requests via WebSockets.
    """
    print(f"Received sync request: {data}")
    
    # Simulate streaming of coordinates
    steps = [
        {"lat": 6.9271, "lng": 79.8612},
        {"lat": 6.9280, "lng": 79.8550},
        {"lat": 6.9300, "lng": 79.8480},
        {"lat": 6.9319, "lng": 79.8430}
    ]
    
    for step in steps:
        time.sleep(2)  # Simulate real-time delay
        emit('route_update', step)
        print(f"Emitted: {step}")

if __name__ == '__main__':
    socketio.run(app, debug=True, port=5000, allow_unsafe_werkzeug=True)
