import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;


void main() {
  runApp(const LogisticsApp());
}

class LogisticsApp extends StatelessWidget {
  const LogisticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Logistics Optimizer',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        fontFamily: 'Outfit',
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  late io.Socket socket;
  
  final LatLng _center = const LatLng(6.9271, 79.8612); // Colombo
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<LatLng> _routePoints = [];
  
  bool _isOptimizing = false;
  String _statusMessage = "Ready to optimize";
  String _efficiency = "0%";

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  void _initSocket() {
    // Replace with your Flask server IP if running on a real device
    // Use localhost for Windows, 10.0.2.2 for Android emulator
    final String backendUrl = Platform.isWindows ? 'http://localhost:5000' : 'http://10.0.2.2:5000';
    
    socket = io.io(backendUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });


    socket.connect();

    socket.onConnect((_) {
      debugPrint('Connected to WebSocket');
      setState(() {
        _statusMessage = "Connected to AI Engine";
      });
    });

    socket.on('route_update', (data) {
      debugPrint('Received route update: $data');
      final lat = data['lat'] as double;
      final lng = data['lng'] as double;
      
      setState(() {
        final point = LatLng(lat, lng);
        _routePoints.add(point);
        _markers.add(Marker(
          markerId: MarkerId('step_${_routePoints.length}'),
          position: point,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ));
        
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: _routePoints,
          color: Colors.deepPurpleAccent,
          width: 5,
        ));
        
        _statusMessage = "Syncing real-time route...";
      });
      
      mapController.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
    });

    socket.onDisconnect((_) => debugPrint('Disconnected'));
  }

  Future<void> _startOptimization() async {
    setState(() {
      _isOptimizing = true;
      _statusMessage = "Analyzing traffic data...";
      _routePoints.clear();
      _markers.clear();
      _polylines.clear();
    });

    try {
      // 1. Fetch initial optimization from REST API
      // Use platform-aware backend URL
      final String backendUrl = Platform.isWindows ? 'http://localhost:5000' : 'http://10.0.2.2:5000';
      
      final response = await http.post(
        Uri.parse('$backendUrl/api/optimize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'origin': 'Colombo Fort',
          'destination': 'Kollupitiya',
        }),
      );


      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _efficiency = result['fuel_saved'];
          _statusMessage = "Route Optimized! Syncing details...";
        });

        // 2. Request real-time sync via WebSocket
        socket.emit('request_route_sync', {'route_id': 'xyz123'});
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error: Backend unreachable";
        _isOptimizing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 14.0,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            style: _mapStyle,
          ),
          
          // Premium Glassmorphic Overlay
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Smart Logistics Assistant",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.radar, color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 8),
                      Text(_statusMessage, style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Efficiency Card
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                if (_efficiency != "0%")
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Colors.deepPurple, Colors.blueAccent]),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)],
                    ),
                    child: Text(
                      "Fuel Efficiency: +$_efficiency",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isOptimizing ? null : _startOptimization,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isOptimizing 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("OPTIMIZE DELIVERY ROUTE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dark Map Style JSON
  final String _mapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#242f3e"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#746855"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#242f3e"}]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#d59563"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#d59563"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [{"color": "#263c3f"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#38414e"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#212a37"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [{"color": "#746855"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#17263c"}]
    }
  ]
  ''';
}
