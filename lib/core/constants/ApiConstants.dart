class ApiConstants {
  // Odoo URL
  static const String baseUrl = 'http://192.168.100.8:8070';
  //static const String baseUrl = 'http://10.126.194.160:8070';
  // API Endpoints
  static const String startPatrol = '/api/patrol/start';
  static const String scanCheckpoint = '/api/patrol/scan';
  static const String updateLocation = '/api/patrol/location';
  static const String endPatrol = '/api/patrol/end';
  static const String getRoute = '/api/patrol/session';
  static const String getCheckpoints = '/api/patrol/checkpoints';
  static const String getSessions = '/api/patrol/sessions';

  // Settings
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // GPS Settings
  static const int gpsUpdateIntervalSeconds = 30;
  static const double minimumAccuracyMeters = 50.0;
}