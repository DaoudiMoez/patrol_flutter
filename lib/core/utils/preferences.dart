import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static const String _keyApiKey = 'api_key';
  static const String _keyDeviceId = 'device_id';
  static const String _keyActiveSessionId = 'active_session_id';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // API Key
  static Future<bool> saveApiKey(String apiKey) async {
    return await _prefs?.setString(_keyApiKey, apiKey) ?? false;
  }

  static String? getApiKey() {
    return _prefs?.getString(_keyApiKey);
  }

  static Future<bool> clearApiKey() async {
    return await _prefs?.remove(_keyApiKey) ?? false;
  }

  // Device ID
  static Future<bool> saveDeviceId(String deviceId) async {
    return await _prefs?.setString(_keyDeviceId, deviceId) ?? false;
  }

  static String? getDeviceId() {
    return _prefs?.getString(_keyDeviceId);
  }

  // Active Session
  static Future<bool> saveActiveSessionId(int sessionId) async {
    return await _prefs?.setInt(_keyActiveSessionId, sessionId) ?? false;
  }

  static int? getActiveSessionId() {
    return _prefs?.getInt(_keyActiveSessionId);
  }

  static Future<bool> clearActiveSessionId() async {
    return await _prefs?.remove(_keyActiveSessionId) ?? false;
  }

  // Clear all
  static Future<bool> clearAll() async {
    return await _prefs?.clear() ?? false;
  }
}