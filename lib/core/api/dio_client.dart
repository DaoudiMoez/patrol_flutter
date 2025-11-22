import 'package:dio/dio.dart';
import 'package:patrol_management/core/constants/apiConstants.dart';
import 'package:patrol_management/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  static Dio? _dio;

  static const String _keySessionId = 'odoo_session_id';
  static const String _keyUid = 'odoo_uid';
  static const String _keyUsername = 'odoo_username';
  static const String _keyIsAdmin = 'is_admin'; // NEW: Track admin status

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

      // Add Odoo session cookie if available
      _dio!.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            await _restoreSession(); // ensure session loaded

            if (_sessionId != null) {
              options.headers['Cookie'] = "session_id=$_sessionId";
            }

            return handler.next(options);
          },
          onError: (error, handler) {
            AppLogger.error('API Error', error);
            return handler.next(error);
          },
        ),
      );

      // Your existing logging interceptor
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
        bool isAdmin = false, // NEW: Save admin status
      }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUid, uid);
    await prefs.setString(_keySessionId, sessionId);
    await prefs.setString(_keyUsername, username);
    await prefs.setBool(_keyIsAdmin, isAdmin);

    _uid = uid;
    _sessionId = sessionId;

    AppLogger.info("Odoo session saved: UID=$uid, Admin=$isAdmin");
  }

  static Future<bool> _restoreSession() async {
    if (_sessionId != null) return true;

    final prefs = await SharedPreferences.getInstance();
    _uid = prefs.getInt(_keyUid);
    _sessionId = prefs.getString(_keySessionId);

    return _uid != null && _sessionId != null;
  }

  // NEW: Check if current user is admin
  static Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsAdmin) ?? false;
  }

  static Future<void> logoutSession() async {
    try {
      await instance.post('/web/session/destroy');
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUid);
    await prefs.remove(_keySessionId);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyIsAdmin);

    _sessionId = null;
    _uid = null;
  }

  // ============================================================
  //                  ODOO AUTHENTICATION
  // ============================================================

  static Future<Map<String, dynamic>> authenticate(
      String username,
      String password,
      String dbName,
      ) async {
    final response = await instance.post(
      '/web/session/authenticate',
      data: {
        "jsonrpc": "2.0",
        "params": {
          "db": dbName,
          "login": username,
          "password": password,
        },
      },
    );

    if (response.data['error'] != null) {
      throw Exception(response.data['error']['data']['message']);
    }

    final result = response.data['result'];

    // Check if user is admin
    final uid = result['uid'];
    bool isAdmin = false;

    try {
      // Query user to check admin status
      final userResult = await callKw(
        'res.users',
        'read',
        args: [
          [uid]
        ],
        kwargs: {
          'fields': ['is_admin']
        },
      );

      if (userResult is List && userResult.isNotEmpty) {
        isAdmin = userResult[0]['is_admin'] ?? false;
      }
    } catch (e) {
      AppLogger.warning('Could not check admin status: $e');
    }

    await saveSession(
      result['uid'],
      result['session_id'],
      username,
      isAdmin: isAdmin,
    );

    return {
      ...result,
      'is_admin': isAdmin,
    };
  }

  // ============================================================
  //                     ODOO RPC HELPERS
  // ============================================================

  static Future<dynamic> callKw(
      String model,
      String method, {
        List<dynamic>? args,
        Map<String, dynamic>? kwargs,
      }) async {
    final response = await instance.post(
      '/web/dataset/call_kw',
      data: {
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
          "model": model,
          "method": method,
          "args": args ?? [],
          "kwargs": kwargs ?? {},
        },
      },
    );

    if (response.data['error'] != null) {
      throw Exception(response.data['error']['data']['message']);
    }

    return response.data['result'];
  }

  static Future<List<int>> search(String model, List domain) async {
    final result = await callKw(model, 'search', args: [domain]);
    return List<int>.from(result);
  }

  static Future<List<Map<String, dynamic>>> read(
      String model,
      List<int> ids,
      List<String> fields,
      ) async {
    final result = await callKw(
      model,
      'read',
      args: [ids],
      kwargs: {'fields': fields},
    );
    return List<Map<String, dynamic>>.from(result);
  }

  static Future<List<Map<String, dynamic>>> searchRead(
      String model,
      List domain, {
        List<String>? fields,
        int? limit,
        int? offset,
        String? order,
      }) async {
    final result = await callKw(
      model,
      'search_read',
      kwargs: {
        'domain': domain,
        if (fields != null) 'fields': fields,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
        if (order != null) 'order': order,
      },
    );
    return List<Map<String, dynamic>>.from(result);
  }

  static Future<int> create(String model, Map<String, dynamic> values) async {
    final result = await callKw(model, 'create', args: [values]);
    return result as int;
  }

  static Future<bool> write(
      String model,
      List<int> ids,
      Map<String, dynamic> values,
      ) async {
    final result = await callKw(model, 'write', args: [ids, values]);
    return result as bool;
  }

  static Future<bool> unlink(String model, List<int> ids) async {
    final result = await callKw(model, 'unlink', args: [ids]);
    return result as bool;
  }
}