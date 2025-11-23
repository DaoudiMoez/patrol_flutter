import 'package:dio/dio.dart';
import 'package:patrol_management/core/constants/apiConstants.dart';
import 'package:patrol_management/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/preferences.dart';

class DioClient {
  static Dio? _dio;

  static const String _keySessionId = 'odoo_session_id';
  static const String _keyUid = 'odoo_uid';
  static const String _keyUsername = 'odoo_username';
  static const String _keyIsAdmin = 'is_admin';

  static String? _sessionId;
  static int? _uid;

  // ============================================================
  //               INSTANCE + INTERCEPTORS
  // ============================================================

  static Dio get instance {
    if (_dio == null) {
      _dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: ApiConstants.connectionTimeout,
          receiveTimeout: ApiConstants.receiveTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      _dio!.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            // Add API key to query parameters for REST API
            final apiKey = await _getApiKey();
            if (apiKey != null && !options.path.contains('/web/')) {
              if (options.queryParameters.isEmpty) {
                options.queryParameters = {'api_key': apiKey};
              }
            }

            return handler.next(options);
          },
          onError: (error, handler) {
            AppLogger.error('API Error', error);
            return handler.next(error);
          },
        ),
      );

      _dio!.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
          logPrint: (obj) => AppLogger.debug(obj.toString()),
        ),
      );
    }
    return _dio!;
  }

  // ============================================================
  //                   SESSION MANAGEMENT
  // ============================================================

  static Future<void> saveSession(
      int uid,
      String sessionId,
      String username, {
        bool isAdmin = false,
      }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUid, uid);
    await prefs.setString(_keySessionId, sessionId);
    await prefs.setString(_keyUsername, username);
    await prefs.setBool(_keyIsAdmin, isAdmin);

    _uid = uid;
    _sessionId = sessionId;

    AppLogger.info("Session saved: UID=$uid, Admin=$isAdmin");
  }

  static Future<bool> _restoreSession() async {
    if (_sessionId != null) return true;

    final prefs = await SharedPreferences.getInstance();
    _uid = prefs.getInt(_keyUid);
    _sessionId = prefs.getString(_keySessionId);

    return _uid != null && _sessionId != null;
  }

  static Future<String?> _getApiKey() async {
    return Preferences.getApiKey();
  }

  static Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsAdmin) ?? false;
  }

  static Future<void> logoutSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUid);
    await prefs.remove(_keySessionId);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyIsAdmin);

    _sessionId = null;
    _uid = null;
  }
}