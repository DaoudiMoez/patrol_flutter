import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:patrol_management/core/constants/app_colors.dart';
import 'package:patrol_management/core/utils/preferences.dart';
import 'package:patrol_management/data/services/patrol_api_service.dart';
import 'package:patrol_management/data/services/map_screenshot_service.dart'; // NEW
import 'package:patrol_management/data/services/admin_api_service.dart'; // NEW
import 'package:patrol_management/presentation/screens/dashboard_screen.dart';
import 'package:patrol_management/presentation/screens/qr_scanner_screen.dart';
import 'package:patrol_management/data/services/gps_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class ActivePatrolScreen extends StatefulWidget {
  final int sessionId;

  const ActivePatrolScreen({super.key, required this.sessionId});

  @override
  State<ActivePatrolScreen> createState() => _ActivePatrolScreenState();
}

class _ActivePatrolScreenState extends State<ActivePatrolScreen> {
  final PatrolApiService _apiService = PatrolApiService();
  final MapScreenshotService _mapScreenshotService = MapScreenshotService(); // NEW
  final AdminApiService _adminApiService = AdminApiService(); // NEW
  final GlobalKey _mapKey = GlobalKey(); // NEW: For screenshot capture

  bool _isEnding = false;
  bool _isCapturingMap = false; // NEW
  List<Map<String, dynamic>> _scannedCheckpoints = [];
  bool _showMap = false;
  MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  LatLng? _currentLocation;
  Timer? _mapUpdateTimer;

  @override
  void initState() {
    super.initState();
    _loadSessionData();

    // Start GPS tracking
    GpsService.startTracking(widget.sessionId);

    // Update map every 10 seconds when map is visible
    _mapUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_showMap) {
        _updateMapData();
      }
    });

    // Initial map load
    _updateMapData();
  }

  Future<void> _loadSessionData() async {
    try {
      final apiKey = Preferences.getApiKey();
      if (apiKey == null) return;

      final route = await _apiService.getRoute(apiKey, widget.sessionId);
      if (mounted) {
        setState(() {
          _scannedCheckpoints = List<Map<String, dynamic>>.from(
            route['events'] ?? [],
          );
        });
      }
    } catch (e) {
      print('Error loading session data: $e');
    }
  }

  Future<void> _endPatrol() async {
    print('🔴 End Patrol button pressed');

    if (_isEnding) return;

    setState(() => _isEnding = true);

    try {
      final apiKey = Preferences.getApiKey();
      if (apiKey == null) throw Exception('No API key');

      // STEP 1: Capture map screenshot if map is visible
      if (_showMap && _routePoints.isNotEmpty) {
        setState(() => _isCapturingMap = true);

        try {
          print('📸 Capturing map screenshot...');

          // Wait for map to render completely
          await Future.delayed(const Duration(milliseconds: 500));

          final screenshot = await _mapScreenshotService.captureMapWithRoute(
            mapKey: _mapKey,
          );

          if (screenshot != null) {
            // Convert to base64
            final base64Image = _mapScreenshotService.bytesToBase64(screenshot);
            print('✅ Map captured: ${screenshot.length} bytes');

            // Upload to server
            try {
              await _adminApiService.uploadMapScreenshot(
                widget.sessionId,
                base64Image,
              );
              print('✅ Map uploaded successfully');
            } catch (e) {
              print('⚠️ Map upload failed, but continuing: $e');
              // Continue even if upload fails
            }
          } else {
            print('⚠️ Map capture returned null');
          }
        } catch (e) {
          print('⚠️ Map capture error (continuing): $e');
          // Continue even if screenshot fails
        } finally {
          setState(() => _isCapturingMap = false);
        }
      }

      // STEP 2: Stop GPS tracking
      GpsService.stopTracking();

      // STEP 3: End patrol via API
      print('Calling endPatrol API...');
      final response = await _apiService.endPatrol(apiKey, widget.sessionId);
      print('API Response: $response');

      await Preferences.clearActiveSessionId();
      print('Cleared active session ID');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patrol ended successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );

      // Wait for snackbar
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      print('Navigating to dashboard...');
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } catch (e, stackTrace) {
      print('❌ Error ending patrol: $e');
      print('Stack trace: $stackTrace');

      if (!mounted) return;

      setState(() {
        _isEnding = false;
        _isCapturingMap = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error ending patrol: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _openScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrScannerScreen(sessionId: widget.sessionId),
      ),
    );

    // Reload session data after scanning
    if (result == true) {
      _loadSessionData();
    }
  }

  Future<void> _updateMapData() async {
    try {
      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get route data from API
      final apiKey = Preferences.getApiKey();
      if (apiKey == null) return;

      final route = await _apiService.getRoute(apiKey, widget.sessionId);

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);

          // Update route points from breadcrumbs
          _routePoints.clear();
          final breadcrumbs = route['breadcrumbs'] as List<dynamic>?;
          if (breadcrumbs != null) {
            for (var breadcrumb in breadcrumbs) {
              final lat = breadcrumb['lat'] as double?;
              final lon = breadcrumb['lon'] as double?;
              if (lat != null && lon != null) {
                _routePoints.add(LatLng(lat, lon));
              }
            }
          }

          // Add current location to route
          if (_currentLocation != null) {
            _routePoints.add(_currentLocation!);
          }
        });
      }
    } catch (e) {
      print('Error updating map: $e');
    }
  }

  @override
  void dispose() {
    GpsService.stopTracking();
    _mapUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please end patrol properly using the End Patrol button'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Session #${widget.sessionId}'),
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          elevation: 0,
          actions: [
            // Toggle Map Button
            IconButton(
              icon: Icon(_showMap ? Icons.list : Icons.map),
              onPressed: () {
                setState(() {
                  _showMap = !_showMap;
                });
                if (_showMap) {
                  _updateMapData();
                }
              },
              tooltip: _showMap ? 'Show List' : 'Show Map',
            ),
          ],
        ),
        body: Column(
          children: [
            // Active Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.success,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.radio_button_checked,
                          color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'PATROL IN PROGRESS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.gps_fixed, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'GPS Tracking Active',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scan Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _openScanner,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.qr_code_scanner, size: 32),
                    SizedBox(width: 16),
                    Text(
                      'Scan Checkpoint',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Map or List View
            Expanded(
              child: _showMap ? _buildMapView() : _buildListView(),
            ),

            // End Patrol Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isEnding ? null : _endPatrol,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isEnding
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isCapturingMap
                            ? 'Saving map...'
                            : 'Ending patrol...',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.stop_circle),
                      SizedBox(width: 8),
                      Text(
                        'End Patrol',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    if (_currentLocation == null && _routePoints.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading map...'),
          ],
        ),
      );
    }

    LatLng center = _currentLocation ?? const LatLng(36.7538, 3.0588);

    return Stack(
      children: [
        // Wrap map with RepaintBoundary for screenshot
        RepaintBoundary(
          key: _mapKey,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 16.0,
              minZoom: 5.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.patrol_app',
              ),
              if (_routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: AppColors.primary,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  ..._scannedCheckpoints.map((checkpoint) {
                    final lat = checkpoint['lat'] as double?;
                    final lon = checkpoint['lon'] as double?;
                    if (lat == null || lon == null) return null;

                    return Marker(
                      point: LatLng(lat, lon),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    );
                  }).whereType<Marker>().toList(),
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.navigation,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Map Legend (outside RepaintBoundary for cleaner screenshot)
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Current', style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Scanned', style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 3,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text('Route', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Recenter button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            onPressed: () {
              if (_currentLocation != null) {
                _mapController.move(_currentLocation!, 16.0);
              }
            },
            child: Icon(Icons.my_location, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    if (_scannedCheckpoints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_2,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No checkpoints scanned yet',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Scan Checkpoint" to begin',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _scannedCheckpoints.length,
      itemBuilder: (context, index) {
        final checkpoint = _scannedCheckpoints[index];
        final checkpointName = checkpoint['checkpoint'] ?? 'Unknown';
        final time = checkpoint['timestamp'] ?? '';
        final code = checkpoint['code'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.success,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              checkpointName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Code: $code'),
                if (time.isNotEmpty && time.length > 19)
                  Text('Time: ${time.substring(0, 19)}'),
              ],
            ),
            trailing: const Icon(
              Icons.check_circle,
              color: Colors.green,
            ),
          ),
        );
      },
    );
  }
}