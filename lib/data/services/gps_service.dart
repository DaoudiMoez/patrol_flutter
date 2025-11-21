import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:patrol_management/core/constants/ApiConstants.dart';
import 'package:patrol_management/core/utils/logger.dart';
import 'package:patrol_management/core/utils/preferences.dart';
import 'package:patrol_management/data/models/location_update_request.dart';
import 'package:patrol_management/data/services/patrol_api_service.dart';
import 'package:intl/intl.dart';

class GpsService {
  static Timer? _timer;
  static final PatrolApiService _apiService = PatrolApiService();
  static bool _isTracking = false;

  /// Start GPS tracking for a patrol session
  static Future<void> startTracking(int sessionId) async {
    if (_isTracking) {
      AppLogger.warning('GPS tracking already started');
      return;
    }

    AppLogger.info('Starting GPS tracking for session $sessionId');
    _isTracking = true;

    // Check and request location permission
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) {
      AppLogger.error('Location permission denied');
      _isTracking = false;
      return;
    }

    // Send location immediately
    await _sendLocationUpdate(sessionId);

    // Then send every 30 seconds
    _timer = Timer.periodic(
      Duration(seconds: ApiConstants.gpsUpdateIntervalSeconds),
          (timer) async {
        if (!_isTracking) {
          timer.cancel();
          return;
        }
        await _sendLocationUpdate(sessionId);
      },
    );
  }

  /// Stop GPS tracking
  static void stopTracking() {
    AppLogger.info('Stopping GPS tracking');
    _isTracking = false;
    _timer?.cancel();
    _timer = null;
  }

  /// Check if GPS is currently tracking
  static bool get isTracking => _isTracking;

  /// Check and request location permission
  static Future<bool> _checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.error('Location permission permanently denied');
        return false;
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      AppLogger.error('Error checking location permission', e);
      return false;
    }
  }

  /// Send location update to server
  static Future<void> _sendLocationUpdate(int sessionId) async {
    try {
      AppLogger.debug('Getting current location...');

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      AppLogger.debug(
        'Location obtained: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)',
      );

      // Check accuracy threshold
      if (position.accuracy > ApiConstants.minimumAccuracyMeters) {
        AppLogger.warning(
          'Location accuracy too low: ${position.accuracy}m (threshold: ${ApiConstants.minimumAccuracyMeters}m)',
        );
        // Still send but log the warning
      }

      // Get API key
      final apiKey = Preferences.getApiKey();
      if (apiKey == null) {
        AppLogger.error('No API key found');
        return;
      }

      // Create request
      final request = LocationUpdateRequest(
        apiKey: apiKey,
        sessionId: sessionId,
        lat: position.latitude,
        lon: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      );

      // Send to API
      AppLogger.debug('Sending location to API...');
      final response = await _apiService.updateLocation(request);

      if (response['error'] != null) {
        AppLogger.error('API error: ${response['error']}');
      } else {
        AppLogger.info('✓ Location update sent successfully');
      }
    } catch (e) {
      AppLogger.error('Error sending location update', e);
    }
  }

  /// Get current location once (for testing)
  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      AppLogger.error('Error getting current location', e);
      return null;
    }
  }
}