import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;

// ─── Constants ───────────────────────────────────────────────────────────────

String get backendUrl =>
    Platform.isAndroid ? 'http://10.0.2.2:5000' : 'http://localhost:5000';

// Colombo-centric coordinates for Sri Lanka logistics
const LatLng kColomboCenter = LatLng(6.9271, 79.8612);

// ─── Color Palette ───────────────────────────────────────────────────────────

class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4A42D1);
  static const Color accent = Color(0xFF00E5FF);
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFAB40);
  static const Color error = Color(0xFFFF5252);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF16213E);
  static const Color textPrimary = Color(0xFFEEEEEE);
  static const Color textSecondary = Color(0xFF9E9E9E);
}

// ─── App Entry ───────────────────────────────────────────────────────────────

void main() {
  runApp(const LogisticsApp());
}

class LogisticsApp extends StatelessWidget {
  const LogisticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Logistics',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.surface,
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
        ),
      ),
      home: const MapScreen(),
    );
  }
}

// ─── Connection Status ───────────────────────────────────────────────────────

enum ConnectionStatus { disconnected, connecting, connected }

enum OptimizationState { idle, analyzing, streaming, completed, error }

// ─── Map Screen ──────────────────────────────────────────────────────────────

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  io.Socket? _socket;

  final Set<Marker> _markers = {};
  final List<LatLng> _routePoints = [];

  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  OptimizationState _optimizationState = OptimizationState.idle;

  String _statusMessage = 'Tap below to optimize a route';
  String _fuelSaved = '';
  String _estimatedTime = '';
  int _routeStepsReceived = 0;
  int _totalRouteSteps = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initSocket();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _socket?.disconnect();
    _socket?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ─── Socket Setup ──────────────────────────────────────────────────────────

  void _initSocket() {
    setState(() => _connectionStatus = ConnectionStatus.connecting);

    _socket = io.io(backendUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 2000,
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      if (!mounted) return;
      setState(() {
        _connectionStatus = ConnectionStatus.connected;
        _statusMessage = 'Connected to AI Engine';
      });
    });

    _socket!.onDisconnect((_) {
      if (!mounted) return;
      setState(() {
        _connectionStatus = ConnectionStatus.disconnected;
        _statusMessage = 'Disconnected from server';
      });
    });

    _socket!.onConnectError((_) {
      if (!mounted) return;
      setState(() {
        _connectionStatus = ConnectionStatus.disconnected;
        _statusMessage = 'Cannot reach backend server';
      });
    });

    _socket!.on('route_update', _handleRouteUpdate);
    _socket!.on('route_complete', _handleRouteComplete);
  }

  void _handleRouteUpdate(dynamic data) {
    if (!mounted) return;

    final lat = (data['lat'] as num).toDouble();
    final lng = (data['lng'] as num).toDouble();
    final label = data['label'] as String? ?? 'Waypoint ${_routePoints.length + 1}';

    setState(() {
      final point = LatLng(lat, lng);
      _routePoints.add(point);
      _routeStepsReceived++;

      _markers.add(Marker(
        markerId: MarkerId('step_$_routeStepsReceived'),
        position: point,
        infoWindow: InfoWindow(title: label),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _routeStepsReceived == 1
              ? BitmapDescriptor.hueGreen
              : BitmapDescriptor.hueAzure,
        ),
      ));

      _statusMessage = 'Receiving route... ($_routeStepsReceived${_totalRouteSteps > 0 ? '/$_totalRouteSteps' : ''} waypoints)';
    });

    _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
  }

  void _handleRouteComplete(dynamic data) {
    if (!mounted) return;
    setState(() {
      _optimizationState = OptimizationState.completed;
      _statusMessage = 'Route optimized successfully!';
    });

    // Fit camera to show entire route
    if (_routePoints.length >= 2) {
      final bounds = _calculateBounds(_routePoints);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 80),
      );
    }
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  // ─── Optimization Logic ────────────────────────────────────────────────────

  Future<void> _startOptimization() async {
    setState(() {
      _optimizationState = OptimizationState.analyzing;
      _statusMessage = 'Analyzing traffic in Colombo...';
      _routePoints.clear();
      _markers.clear();
      _fuelSaved = '';
      _estimatedTime = '';
      _routeStepsReceived = 0;
      _totalRouteSteps = 0;
    });

    try {
      final response = await http
          .post(
            Uri.parse('$backendUrl/api/optimize'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'origin': 'Colombo Fort',
              'destination': 'Kollupitiya',
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;

        setState(() {
          _optimizationState = OptimizationState.streaming;
          _fuelSaved = result['fuel_saved'] as String? ?? '';
          _estimatedTime = result['estimated_time'] as String? ?? '';
          _statusMessage = 'Route found! Streaming coordinates...';

          final route = result['optimized_route'] as List<dynamic>?;
          _totalRouteSteps = route?.length ?? 0;
        });

        // Request real-time coordinate streaming
        _socket?.emit('request_route_sync', {'route_id': 'colombo_opt_001'});
      } else {
        setState(() {
          _optimizationState = OptimizationState.error;
          _statusMessage = 'Server error (${response.statusCode})';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _optimizationState = OptimizationState.error;
        _statusMessage = 'Error: ${e is http.ClientException ? 'Backend unreachable' : e.toString()}';
      });
    }
  }

  void _resetOptimization() {
    setState(() {
      _optimizationState = OptimizationState.idle;
      _statusMessage = 'Tap below to optimize a route';
      _routePoints.clear();
      _markers.clear();
      _fuelSaved = '';
      _estimatedTime = '';
      _routeStepsReceived = 0;
      _totalRouteSteps = 0;
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(target: kColomboCenter, zoom: 14.0),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: const CameraPosition(
              target: kColomboCenter,
              zoom: 14.0,
            ),
            markers: _markers,
            polylines: _buildPolylines(),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            style: _mapStyle,
          ),

          // Top Status Bar
          Positioned(
            top: mediaQuery.padding.top + 12,
            left: 16,
            right: 16,
            child: _buildStatusCard(),
          ),

          // Bottom Action Panel
          Positioned(
            bottom: mediaQuery.padding.bottom + 16,
            left: 16,
            right: 16,
            child: _buildActionPanel(),
          ),

          // Connection indicator
          Positioned(
            top: mediaQuery.padding.top + 12,
            right: 24,
            child: _buildConnectionDot(),
          ),
        ],
      ),
    );
  }

  // ─── Polylines (rebuilt each frame, no duplicate IDs) ──────────────────────

  Set<Polyline> _buildPolylines() {
    if (_routePoints.length < 2) return {};

    return {
      Polyline(
        polylineId: const PolylineId('optimized_route'),
        points: List.from(_routePoints),
        color: AppColors.primary,
        width: 5,
        patterns: [PatternItem.dot, PatternItem.gap(8)],
      ),
    };
  }

  // ─── Status Card (Glassmorphic) ────────────────────────────────────────────

  Widget _buildStatusCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.route_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Smart Logistics Assistant',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatusIcon(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Route stats row
              if (_fuelSaved.isNotEmpty || _estimatedTime.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (_fuelSaved.isNotEmpty)
                      _buildStatChip(
                        Icons.local_gas_station_rounded,
                        'Fuel: +$_fuelSaved',
                        AppColors.success,
                      ),
                    if (_fuelSaved.isNotEmpty && _estimatedTime.isNotEmpty)
                      const SizedBox(width: 10),
                    if (_estimatedTime.isNotEmpty)
                      _buildStatChip(
                        Icons.timer_rounded,
                        _estimatedTime,
                        AppColors.accent,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    final isActive = _optimizationState == OptimizationState.analyzing ||
        _optimizationState == OptimizationState.streaming;

    final color = switch (_optimizationState) {
      OptimizationState.idle => AppColors.textSecondary,
      OptimizationState.analyzing => AppColors.warning,
      OptimizationState.streaming => AppColors.accent,
      OptimizationState.completed => AppColors.success,
      OptimizationState.error => AppColors.error,
    };

    if (isActive) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Icon(
            Icons.radar_rounded,
            color: color.withValues(alpha: _pulseAnimation.value),
            size: 16,
          );
        },
      );
    }

    final icon = switch (_optimizationState) {
      OptimizationState.completed => Icons.check_circle_rounded,
      OptimizationState.error => Icons.error_rounded,
      _ => Icons.circle_outlined,
    };

    return Icon(icon, color: color, size: 16);
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Connection Dot ────────────────────────────────────────────────────────

  Widget _buildConnectionDot() {
    final color = switch (_connectionStatus) {
      ConnectionStatus.connected => AppColors.success,
      ConnectionStatus.connecting => AppColors.warning,
      ConnectionStatus.disconnected => AppColors.error,
    };

    final label = switch (_connectionStatus) {
      ConnectionStatus.connected => 'Live',
      ConnectionStatus.connecting => '...',
      ConnectionStatus.disconnected => 'Off',
    };

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(
                    alpha: _connectionStatus == ConnectionStatus.connecting
                        ? _pulseAnimation.value
                        : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Action Panel ──────────────────────────────────────────────────────────

  Widget _buildActionPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Route progress indicator
        if (_optimizationState == OptimizationState.streaming &&
            _totalRouteSteps > 0) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _routeStepsReceived / _totalRouteSteps,
              backgroundColor: AppColors.surface.withValues(alpha: 0.8),
              color: AppColors.primary,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Main action button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: _buildActionButton(),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    if (_optimizationState == OptimizationState.completed) {
      return ElevatedButton.icon(
        onPressed: _resetOptimization,
        icon: const Icon(Icons.refresh_rounded, size: 20),
        label: const Text(
          'NEW ROUTE',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
      );
    }

    if (_optimizationState == OptimizationState.error) {
      return ElevatedButton.icon(
        onPressed: _startOptimization,
        icon: const Icon(Icons.replay_rounded, size: 20),
        label: const Text(
          'RETRY OPTIMIZATION',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
      );
    }

    final isWorking = _optimizationState == OptimizationState.analyzing ||
        _optimizationState == OptimizationState.streaming;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isWorking
            ? null
            : const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: isWorking
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton.icon(
        onPressed: isWorking ? null : _startOptimization,
        icon: isWorking
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white70,
                ),
              )
            : const Icon(Icons.bolt_rounded, size: 22),
        label: Text(
          isWorking ? 'OPTIMIZING...' : 'OPTIMIZE ROUTE',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isWorking ? AppColors.surfaceLight : Colors.transparent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.surfaceLight,
          disabledForegroundColor: Colors.white70,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
    );
  }

  // ─── Map Style ─────────────────────────────────────────────────────────────

  final String _mapStyle = '''[
    {"elementType":"geometry","stylers":[{"color":"#1d2c4d"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},
    {"featureType":"administrative.country","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},
    {"featureType":"administrative.land_parcel","elementType":"labels.text.fill","stylers":[{"color":"#64779e"}]},
    {"featureType":"administrative.province","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},
    {"featureType":"landscape.man_made","elementType":"geometry.stroke","stylers":[{"color":"#334e87"}]},
    {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#023e58"}]},
    {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#283d6a"}]},
    {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6f9ba5"}]},
    {"featureType":"poi","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c4d"}]},
    {"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#023e58"}]},
    {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#3C7680"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a7d"}]},
    {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},
    {"featureType":"road","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c4d"}]},
    {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2c6675"}]},
    {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#255763"}]},
    {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#b0d5ce"}]},
    {"featureType":"road.highway","elementType":"labels.text.stroke","stylers":[{"color":"#023e58"}]},
    {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},
    {"featureType":"transit","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c4d"}]},
    {"featureType":"transit.line","elementType":"geometry.fill","stylers":[{"color":"#283d6a"}]},
    {"featureType":"transit.station","elementType":"geometry","stylers":[{"color":"#3a4762"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1626"}]},
    {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4e6d70"}]}
  ]''';
}
