import 'package:patrol_management/data/models/route_config.dart';
import 'package:patrol_management/data/models/patrol_history.dart';
import 'package:patrol_management/data/models/checkpoint.dart';
import 'package:patrol_management/core/api/dio_client.dart';
import 'package:patrol_management/core/utils/logger.dart';

class AdminApiService {
  // Odoo model names
  static const String routeModel = 'patrol.route';
  static const String checkpointModel = 'patrol.checkpoint';
  static const String patrolSessionModel = 'patrol.session';
  static const String locationTrackModel = 'patrol.location.track';
  static const String routeCheckpointModel = 'patrol.route.checkpoint';
  static const String scanModel = 'patrol.scan';

  // ============================================================
  //                   ROUTE CONFIGURATION
  // ============================================================

  Future<List<RouteConfig>> getAllRoutes() async {
    try {
      final routes = await DioClient.searchRead(
        routeModel,
        [],
        fields: ['id', 'name', 'description', 'is_active', 'create_date', 'write_date'],
        order: 'name asc',
      );

      List<RouteConfig> routeConfigs = [];
      for (var route in routes) {
        final checkpoints = await _getRouteCheckpoints(route['id']);

        routeConfigs.add(RouteConfig(
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
        ));
      }

      return routeConfigs;
    } catch (e) {
      AppLogger.error('Error fetching routes', e);
      rethrow;
    }
  }

  Future<List<CheckpointOrder>> _getRouteCheckpoints(int routeId) async {
    try {
      final routeCheckpoints = await DioClient.searchRead(
        routeCheckpointModel,
        [
          ['route_id', '=', routeId]
        ],
        fields: ['checkpoint_id', 'sequence', 'is_required'],
        order: 'sequence asc',
      );

      List<CheckpointOrder> checkpoints = [];
      for (var rc in routeCheckpoints) {
        final checkpointId =
        rc['checkpoint_id'] is List ? rc['checkpoint_id'][0] : rc['checkpoint_id'];
        final checkpointName = rc['checkpoint_id'] is List
            ? rc['checkpoint_id'][1]
            : 'Checkpoint $checkpointId';

        checkpoints.add(CheckpointOrder(
          checkpointId: checkpointId,
          checkpointName: checkpointName,
          order: rc['sequence'] ?? 0,
          isRequired: rc['is_required'] ?? true,
        ));
      }

      return checkpoints;
    } catch (e) {
      AppLogger.error('Error fetching route checkpoints', e);
      return [];
    }
  }

  Future<RouteConfig> getRouteById(int routeId) async {
    try {
      final routes = await DioClient.read(
        routeModel,
        [routeId],
        ['id', 'name', 'description', 'is_active', 'create_date', 'write_date'],
      );

      if (routes.isEmpty) {
        throw Exception('Route not found');
      }

      final route = routes.first;
      final checkpoints = await _getRouteCheckpoints(routeId);

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
      // Create the route
      final routeId = await DioClient.create(
        routeModel,
        {
          'name': request.name,
          'description': request.description,
          'is_active': true,
        },
      );

      // Create route checkpoints
      for (var checkpoint in request.checkpoints) {
        await DioClient.create(
          routeCheckpointModel,
          {
            'route_id': routeId,
            'checkpoint_id': checkpoint.checkpointId,
            'sequence': checkpoint.order,
            'is_required': checkpoint.isRequired,
          },
        );
      }

      return await getRouteById(routeId);
    } catch (e) {
      AppLogger.error('Error creating route', e);
      rethrow;
    }
  }

  Future<RouteConfig> updateRoute(int routeId, CreateRouteRequest request) async {
    try {
      // Update route
      await DioClient.write(
        routeModel,
        [routeId],
        {
          'name': request.name,
          'description': request.description,
        },
      );

      // Delete existing checkpoints
      final existingCheckpoints = await DioClient.search(
        routeCheckpointModel,
        [
          ['route_id', '=', routeId]
        ],
      );
      if (existingCheckpoints.isNotEmpty) {
        await DioClient.unlink(routeCheckpointModel, existingCheckpoints);
      }

      // Create new checkpoints
      for (var checkpoint in request.checkpoints) {
        await DioClient.create(
          routeCheckpointModel,
          {
            'route_id': routeId,
            'checkpoint_id': checkpoint.checkpointId,
            'sequence': checkpoint.order,
            'is_required': checkpoint.isRequired,
          },
        );
      }

      return await getRouteById(routeId);
    } catch (e) {
      AppLogger.error('Error updating route', e);
      rethrow;
    }
  }

  Future<void> deleteRoute(int routeId) async {
    try {
      // Delete route checkpoints first
      final checkpoints = await DioClient.search(
        routeCheckpointModel,
        [
          ['route_id', '=', routeId]
        ],
      );
      if (checkpoints.isNotEmpty) {
        await DioClient.unlink(routeCheckpointModel, checkpoints);
      }

      // Delete route
      await DioClient.unlink(routeModel, [routeId]);
    } catch (e) {
      AppLogger.error('Error deleting route', e);
      rethrow;
    }
  }

  Future<void> toggleRouteStatus(int routeId, bool isActive) async {
    try {
      await DioClient.write(
        routeModel,
        [routeId],
        {'is_active': isActive},
      );
    } catch (e) {
      AppLogger.error('Error toggling route status', e);
      rethrow;
    }
  }

  Future<List<Checkpoint>> getAllCheckpoints() async {
    try {
      final checkpoints = await DioClient.searchRead(
        checkpointModel,
        [],
        fields: ['id', 'name', 'code', 'latitude', 'longitude', 'description'],
        order: 'name asc',
      );

      return checkpoints.map((cp) {
        // Ensure 'code' is present for compatibility
        if (!cp.containsKey('code') && cp.containsKey('qr_code')) {
          cp['code'] = cp['qr_code'];
        }
        return Checkpoint.fromJson(cp);
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching checkpoints', e);
      rethrow;
    }
  }

  // ============================================================
  //                   PATROL HISTORY
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
      List<dynamic> domain = [];

      if (userId != null) {
        domain.add(['user_id', '=', userId]);
      }
      if (startDate != null) {
        domain.add(['start_time', '>=', startDate.toIso8601String()]);
      }
      if (endDate != null) {
        domain.add(['start_time', '<=', endDate.toIso8601String()]);
      }
      if (status != null) {
        domain.add(['state', '=', status]);
      }

      final sessions = await DioClient.searchRead(
        patrolSessionModel,
        domain,
        fields: [
          'id',
          'guard_id',
          'start_time',
          'end_time',
          'state',
          'route_screenshot',
        ],
        limit: perPage,
        offset: (page - 1) * perPage,
        order: 'start_time desc',
      );

      List<PatrolHistory> history = [];
      for (var session in sessions) {
        final checkpoints = await _getSessionCheckpoints(session['id']);
        final locationPoints = await _getSessionLocationPoints(session['id']);

        history.add(PatrolHistory(
          id: session['id'],
          userId: session['guard_id'] is List ? session['guard_id'][0] : session['guard_id'],
          userName: session['guard_id'] is List
              ? session['guard_id'][1]
              : 'User ${session['guard_id']}',
          startTime: DateTime.parse(session['start_time']),
          endTime:
          session['end_time'] != null ? DateTime.parse(session['end_time']) : null,
          status: session['state'] ?? 'in_progress',
          checkpoints: checkpoints,
          locationPoints: locationPoints,
          mapImageUrl: session['route_screenshot'] != null ? 'has_image' : null,
          totalDistance: null, // Calculated on Odoo side if needed
          duration: null, // Calculated on Odoo side if needed
        ));
      }

      return history;
    } catch (e) {
      AppLogger.error('Error fetching patrol history', e);
      rethrow;
    }
  }

  Future<List<PatrolCheckpointHistory>> _getSessionCheckpoints(int sessionId) async {
    try {
      final scans = await DioClient.searchRead(
        scanModel,
        [
          ['session_id', '=', sessionId]
        ],
        fields: ['checkpoint_id', 'scan_time', 'sequence'],
        order: 'sequence asc',
      );

      return scans.map((scan) {
        return PatrolCheckpointHistory(
          checkpointId:
          scan['checkpoint_id'] is List ? scan['checkpoint_id'][0] : scan['checkpoint_id'],
          checkpointName:
          scan['checkpoint_id'] is List ? scan['checkpoint_id'][1] : 'Checkpoint',
          scannedAt: scan['scan_time'] != null ? DateTime.parse(scan['scan_time']) : null,
          isCompleted: scan['scan_time'] != null,
          orderInRoute: scan['sequence'] ?? 0,
        );
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching session checkpoints', e);
      return [];
    }
  }

  Future<List<PatrolLocationPoint>> _getSessionLocationPoints(int sessionId) async {
    try {
      final locations = await DioClient.searchRead(
        locationTrackModel,
        [
          ['session_id', '=', sessionId]
        ],
        fields: ['latitude', 'longitude', 'timestamp'],
        order: 'timestamp asc',
        limit: 1000,
      );

      return locations.map((loc) {
        return PatrolLocationPoint(
          latitude: (loc['latitude'] ?? loc['lat'] ?? 0).toDouble(),
          longitude: (loc['longitude'] ?? loc['lon'] ?? 0).toDouble(),
          timestamp: DateTime.parse(loc['timestamp']),
        );
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching location points', e);
      return [];
    }
  }

  Future<PatrolHistory> getPatrolHistoryById(int patrolId) async {
    try {
      final sessions = await DioClient.read(
        patrolSessionModel,
        [patrolId],
        [
          'id',
          'guard_id',
          'start_time',
          'end_time',
          'state',
          'route_screenshot',
        ],
      );

      if (sessions.isEmpty) {
        throw Exception('Patrol session not found');
      }

      final session = sessions.first;
      final checkpoints = await _getSessionCheckpoints(patrolId);
      final locationPoints = await _getSessionLocationPoints(patrolId);

      return PatrolHistory(
        id: session['id'],
        userId: session['guard_id'] is List ? session['guard_id'][0] : session['guard_id'],
        userName:
        session['guard_id'] is List ? session['guard_id'][1] : 'User ${session['guard_id']}',
        startTime: DateTime.parse(session['start_time']),
        endTime: session['end_time'] != null ? DateTime.parse(session['end_time']) : null,
        status: session['state'] ?? 'in_progress',
        checkpoints: checkpoints,
        locationPoints: locationPoints,
        mapImageUrl: session['route_screenshot'] != null ? 'has_image' : null,
        totalDistance: null,
        duration: null,
      );
    } catch (e) {
      AppLogger.error('Error fetching patrol details', e);
      rethrow;
    }
  }

  Future<String> uploadMapScreenshot(int patrolId, String base64Image) async {
    try {
      await DioClient.write(
        patrolSessionModel,
        [patrolId],
        {'route_screenshot': base64Image},
      );

      return '/web/image/patrol.session/$patrolId/route_screenshot';
    } catch (e) {
      AppLogger.error('Error uploading map screenshot', e);
      rethrow;
    }
  }

  // ============================================================
  //                   DASHBOARD STATISTICS
  // ============================================================

  Future<Map<String, dynamic>> getDashboardStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<dynamic> domain = [];
      if (startDate != null) {
        domain.add(['start_time', '>=', startDate.toIso8601String()]);
      }
      if (endDate != null) {
        domain.add(['start_time', '<=', endDate.toIso8601String()]);
      }

      // Total patrols
      final totalPatrols = await DioClient.search(patrolSessionModel, domain);

      // Active users
      final sessions = await DioClient.searchRead(
        patrolSessionModel,
        domain,
        fields: ['guard_id'],
      );
      final uniqueUsers = sessions
          .map((s) => s['guard_id'] is List ? s['guard_id'][0] : s['guard_id'])
          .toSet()
          .length;

      // Total routes
      final routes = await DioClient.search(routeModel, []);

      // Today's patrols
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayPatrols = await DioClient.search(
        patrolSessionModel,
        [
          ['start_time', '>=', todayStart.toIso8601String()]
        ],
      );

      // Recent patrols
      final recentSessions = await DioClient.searchRead(
        patrolSessionModel,
        [],
        fields: ['guard_id', 'start_time', 'state'],
        limit: 5,
        order: 'start_time desc',
      );

      return {
        'total_patrols': totalPatrols.length,
        'active_users': uniqueUsers,
        'total_routes': routes.length,
        'today_patrols': todayPatrols.length,
        'recent_patrols': recentSessions
            .map((s) => {
          'user_name': s['guard_id'] is List ? s['guard_id'][1] : 'User',
          'start_time': s['start_time'],
          'status': s['state'] ?? 'unknown',
        })
            .toList(),
      };
    } catch (e) {
      AppLogger.error('Error fetching dashboard stats', e);
      rethrow;
    }
  }
}