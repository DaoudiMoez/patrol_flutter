import 'package:dio/dio.dart';
import 'package:patrol_management/core/api/dio_client.dart';
import 'package:patrol_management/core/constants/apiConstants.dart';
import 'package:patrol_management/data/models/checkpoint.dart';
import 'package:patrol_management/data/models/location_update_request.dart';
import 'package:patrol_management/data/models/scan_request.dart';
import 'package:patrol_management/data/models/scan_response.dart';
import 'package:patrol_management/data/models/start_patrol_request.dart';
import 'package:patrol_management/data/models/start_patrol_response.dart';

class PatrolApiService {
  final Dio _dio = DioClient.instance;

  // Start Patrol
  Future<StartPatrolResponse> startPatrol(StartPatrolRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.startPatrol,
        data: request.toJson(),
      );
      return StartPatrolResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Scan Checkpoint
  Future<ScanResponse> scanCheckpoint(ScanRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.scanCheckpoint,
        data: request.toJson(),
      );
      return ScanResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update Location (GPS Breadcrumb)
  Future<Map<String, dynamic>> updateLocation(
      LocationUpdateRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.updateLocation,
        data: request.toJson(),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // End Patrol
  Future<Map<String, dynamic>> endPatrol(String apiKey, int sessionId) async {
    try {
      final response = await _dio.post(
        ApiConstants.endPatrol,
        data: {
          'api_key': apiKey,
          'session_id': sessionId,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get Checkpoints
  Future<List<Checkpoint>> getCheckpoints(String apiKey) async {
    try {
      final response = await _dio.get(
        ApiConstants.getCheckpoints,
        queryParameters: {'api_key': apiKey},
      );
      final List checkpointsJson = response.data['checkpoints'] ?? [];
      return checkpointsJson
          .map((json) => Checkpoint.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get Sessions
  Future<List<dynamic>> getSessions(String apiKey, {int limit = 50}) async {
    try {
      final response = await _dio.get(
        ApiConstants.getSessions,
        queryParameters: {
          'api_key': apiKey,
          'limit': limit,
        },
      );
      return response.data['sessions'] ?? [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get Route
  Future<Map<String, dynamic>> getRoute(String apiKey, int sessionId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.getRoute}/$sessionId/route',
        queryParameters: {'api_key': apiKey},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error handler
  String _handleError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet.';
    } else if (error.type == DioExceptionType.connectionError) {
      return 'No internet connection';
    } else if (error.response != null) {
      final data = error.response!.data;
      if (data is Map && data.containsKey('error')) {
        return data['error'].toString();
      }
      return 'Server error: ${error.response!.statusCode}';
    }
    return 'An unexpected error occurred';
  }

  // Get Users List
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await _dio.get(
        '/api/patrol/users',
      );
      final List users = response.data['users'] ?? [];
      return users.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}