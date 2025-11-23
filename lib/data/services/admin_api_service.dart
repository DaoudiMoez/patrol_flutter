import 'package:dio/dio.dart';
import 'package:patrol_management/data/models/route_config.dart';
import 'package:patrol_management/data/models/patrol_history.dart';
import 'package:patrol_management/data/models/checkpoint.dart';
import 'package:patrol_management/core/api/dio_client.dart';
import 'package:patrol_management/core/utils/logger.dart';
import 'package:patrol_management/core/utils/preferences.dart';

class AdminApiService {
  final Dio _dio = DioClient.instance;

  // ============================================================
  //                   ROUTE CONFIGURATION (Using REST API)
  // ============================================================

  Future<List<RouteConfig>> getAllRoutes() async {
    try {
      final apiKey = Preferences.getApiKey();
      if (apiKey == null) throw Exception('No API key found');

      final response = await _dio.get(
        '/api/patrol/routes',
        queryParameters: {'api_key': apiKey},
      );

      if (response.data['error'] != null) {
        throw Exception(response.data['error']);
      }

      final List routes = response.data['routes'] ?? [];

      return routes.map((route) {
        final List checkpointsList = route['checkpoints'] ?? [];

        final checkpoints = checkpointsList.map((cp) {
          return CheckpointOrder(
            checkpointId: cp['checkpoint_id'],
            checkpointName: cp['checkpoint_name'],
            order: cp['sequence'],
            isRequired: cp['is_required'] ?? true,
          );
        }).toList();

        return RouteConfig(
          id: route['id'],
          name: route['name'],
          description: route['description'] ?? '',
          checkpoints: checkpoints,
          isActive: route['is_active'] ?? true,
          createdAt: route['create_date'] != null
              ? DateTime.parse(route['create_date'])
              : null,
          updatedAt: route['write_date'] != null
              ? DateTime.parse(route['write_date'])
              : null,
        );
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching routes', e);
      rethrow;
    }
  }

  Future<RouteConfig> getRouteById(int routeId) async {
    try {
      final apiKey = Preferences.getApiKey();
      if (apiKey == null) throw Exception('No API key found');

      final response = await _dio.get(
        '/api/patrol/routes/$routeId',
        queryParameters: {'api_key': apiKey},
      );

      if (response.data['error'] != null) {
        throw Exception(response.data['error']);
      }

      final route = response.data;
      final List checkpointsList = route['checkpoints'] ?? [];

      final checkpoints = checkpointsList.map((cp) {
        return CheckpointOrder(
          checkpointId: cp['checkpoint_id'],
          checkpointName: cp['checkpoint_name'],
          order: cp['sequence'],
          isRequired: cp['is_required'] ?? true,
        );
      }).toList();

      return RouteConfig(
        id: route['id'],
        name: route['name'],
        description: route['description'] ?? '',
        checkpoints: checkpoints,
        isActive: route['is_active'] ?? true,
        createdAt: route['create_date'] != null
            ? DateTime.parse(route['create_date'])
            : null,
        updatedAt: route['write_date'] != null
            ? DateTime.parse(route['write_date'])
            : null,
      );
    } catch (e) {
      AppLogger.error('Error fetching route', e);
      rethrow;
    }
  }

  Future<RouteConfig> createRoute(CreateRouteRequest request) async {
    try {
      final apiKey = Preferences.getApiKey();
      if (apiKey == null) throw Exception('No API key found');

      final response = await _dio.post(
        '/api/patrol/routes',
        data: {
          'api_key': apiKey,
          'name': request.name,
          'description': request.description,
          'checkpoints': request.checkpoints.map((cp) => cp.toJson()).toList(),
        },
      );

      if (response.data['error'] != null) {
        throw Exception(response.data['error']);
      }

      final routeId = response.data['route_id'];
      return await getRouteById(routeId);
    } catch (e) {
      AppLogger.error('Error creating route', e);
      rethrow;
    }
  }

  Future<RouteConfig> updateRoute(int routeId, CreateRouteRequest request) async {
    try {
      final apiKey = Preferences.getApiKey();
      if (apiKey == null) throw Exception('No API key found');

      final response = await _dio.put(
        '/api/patrol/routes/$routeId',
        data: {
          'api_key': apiKey,
          'name': request.name,
          'description': request.description,
          'checkpoints': request.checkpoints.map((cp) => cp.toJson()).toList(),
        },
      );

      if (response.data['error'] != null) {
        throw Exception(response.data['error']);
      }

      return await getRouteById(routeId);
    } catch (e) {
      AppLogger.error('Error updating route', e);
      rethrow;
    }
  }

  Future<void> deleteRoute(int routeId) async {
    try {
      final apiKey = Preferences.getApiKey();
      if (apiKey == null) throw Exception('No API key found');

      final response = await _dio.delete(
        '/api/patrol/routes/$routeId',
        queryParameters: {'api_key': apiKey},
      );

      if (response.data['error'] != null) {
        throw Exception(response.data['error']);
      }
    } catch (e) {
      AppLogger.error('Error deleting route', e);
      rethrow;
    }
  }

  Future<void> toggleRouteStatus(int routeId, bool isActive) async {
    try {
      final apiKey = Preferences.getApiKey();
      if (apiKey == null) throw Exception('No API key found');

      final response = await _dio.post(
        '/api/patrol/routes/$routeId/toggle',
        data: {
          'api_key': apiKey,
          'is_active': isActive,
        },
      );

      if (response.data['error'] != null) {
        throw Exception(response.data['error']);
      }
    } catch (e) {
      AppLogger.error('Error toggling route status', e);
      rethrow;
    }
  }

  Future<List<Checkpoint>> getAllCheckpoints() async {
    try {
      final apiKey = Preferences.getApiKey();
      if (apiKey == null) throw Exception('No API key found');

      final response = await _dio.get(
        '/api/patrol/checkpoints',
        queryParameters: {'api_key': apiKey},
      );

      if (response.data['error'] != null) {
        throw Exception(response.data['error']);
      }

      final List checkpoints = response.data['checkpoints'] ?? [];

      return checkpoints.map((cp) {
        return Checkpoint(
          id: cp['id'],
          name: cp['name'],
          code: cp['code'],
          latitude: cp['latitude'],
          longitude: cp['longitude'],
          description: cp['description'],
        );
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching checkpoints', e);
      rethrow;
    }
  }

  // ============================================================
  //                   PATROL HISTORY (Using REST API)
  // ============================================================

  Future<List<PatrolHistory>> getAllPatrolHistory({
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final apiKey = Preferences.getApiKey();
      if (apiKey == null) throw Exception('No API key found');

      final queryParams = <String, dynamic>{'api_key': apiKey};

      if (userId != null) queryParams['user_id'] = userId;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (status != null && status != 'all') queryParams['status'] = status;
      queryParams['page'] = page;
      queryParams['per_page'] = perPage;

      final response = await _dio.get(
        '/api/patrol/history',
        queryParameters: queryParams,
      );

      if (response.data['error'] != null) {
        throw Exception(response.data['error']);
      }

      final List patrols = response.data['patrols'] ?? [];

      return patrols.map((patrol) {
        final List checkpointsList = patrol['checkpoints'] ?? [];
        final checkpoints = checkpointsList.map((cp) {
          return PatrolCheckpointHistory(
            checkpointId: cp['checkpoint_id'] ?? 0,
            checkpointName: cp['checkpoint_name'] ?? 'Unknown',
            scannedAt: cp['scan_time'] != null ? DateTime.parse(cp['scan_time']) : null,
            isCompleted: cp['is_completed'] ?? false,
            orderInRoute: cp['sequence'] ?? 0,
          );
        }).toList();

        final List locationsList = patrol['location_points'] ?? [];
        final locationPoints = locationsList.map((loc) {
          return PatrolLocationPoint(
            latitude: (loc['latitude'] ?? 0).toDouble(),
            longitude: (loc['longitude'] ?? 0).toDouble(),
            timestamp: DateTime.parse(loc['timestamp']),
          );
        }).toList();

        return PatrolHistory(
          id: patrol['id'],
          userId: patrol['user_id'],
          userName: patrol['user_name'],
          startTime: DateTime.parse(patrol['start_time']),
          endTime: patrol['end_time'] != null ? DateTime.parse(patrol['end_time']) : null,
          status: patrol['state'] ?? 'unknown',
          checkpoints: checkpoints,
          locationPoints: locationPoints,
          mapImageUrl: patrol['map_image'],
          totalDistance: patrol['total_distance'],
          duration: patrol['duration'],
        );
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching patrol history', e);
      rethrow;
    }
  }

  Future<PatrolHistory> getPatrolHistoryById(int patrolId) async {
    try {
      // Just get from the list with a filter
      final patrols = await getAllPatrolHistory(perPage: 1);

      if (patrols.isEmpty) {
        throw Exception('Patrol session not found');
      }

      return patrols.first;
    } catch (e) {
      AppLogger.error('Error fetching patrol details', e);
      rethrow;
    }
  }

  Future<String> uploadMapScreenshot(int patrolId, String base64Image) async {
    try {
      final apiKey = Preferences.getApiKey();
      if (apiKey == null) throw Exception('No API key found');

      final response = await _dio.post(
        '/api/patrol/session/$patrolId/screenshot',
        data: {
          'api_key': apiKey,
          'screenshot': base64Image,
        },
      );

      if (response.data['error'] != null) {
        throw Exception(response.data['error']);
      }

      return '/web/image/patrol.session/$patrolId/route_screenshot';
    } catch (e) {
      AppLogger.error('Error uploading map screenshot', e);
      rethrow;
    }
  }

  // ============================================================
  //                   DASHBOARD STATISTICS (Using REST API)
  // ============================================================

  Future<Map<String, dynamic>> getDashboardStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final apiKey = Preferences.getApiKey();
      if (apiKey == null) throw Exception('No API key found');

      final queryParams = <String, dynamic>{'api_key': apiKey};

      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final response = await _dio.get(
        '/api/patrol/dashboard/stats',
        queryParameters: queryParams,
      );

      if (response.data['error'] != null) {
        throw Exception(response.data['error']);
      }

      return response.data;
    } catch (e) {
      AppLogger.error('Error fetching dashboard stats', e);
      rethrow;
    }
  }
}