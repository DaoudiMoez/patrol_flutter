import 'package:flutter/material.dart';
import '../../data/services/admin_api_service.dart';
import '../../data/models/route_config.dart';
import '../../core/utils/logger.dart';
import 'create_route_screen.dart';
import 'route_detail_screen.dart';

class RouteManagementScreen extends StatefulWidget {
  const RouteManagementScreen({Key? key}) : super(key: key);

  @override
  State<RouteManagementScreen> createState() => _RouteManagementScreenState();
}

class _RouteManagementScreenState extends State<RouteManagementScreen> {
  final AdminApiService _adminApiService = AdminApiService();
  List<RouteConfig> _routes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() => _isLoading = true);
    try {
      final routes = await _adminApiService.getAllRoutes();
      setState(() {
        _routes = routes;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading routes', e);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading routes: $e')),
        );
      }
    }
  }

  Future<void> _deleteRoute(RouteConfig route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: Text('Are you sure you want to delete "${route.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminApiService.deleteRoute(route.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Route deleted successfully')),
          );
        }
        _loadRoutes();
      } catch (e) {
        AppLogger.error('Error deleting route', e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting route: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleRouteStatus(RouteConfig route) async {
    try {
      await _adminApiService.toggleRouteStatus(route.id, !route.isActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              route.isActive
                  ? 'Route deactivated'
                  : 'Route activated',
            ),
          ),
        );
      }
      _loadRoutes();
    } catch (e) {
      AppLogger.error('Error toggling route status', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoutes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routes.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadRoutes,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _routes.length,
          itemBuilder: (context, index) {
            final route = _routes[index];
            return _buildRouteCard(route);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateRouteScreen(),
            ),
          );
          if (result == true) {
            _loadRoutes();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Route'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No routes configured',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first patrol route',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateRouteScreen(),
                ),
              );
              if (result == true) {
                _loadRoutes();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Route'),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(RouteConfig route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: route.isActive ? Colors.green : Colors.grey,
              child: const Icon(Icons.route, color: Colors.white),
            ),
            title: Text(
              route.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (route.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(route.description),
                ],
                const SizedBox(height: 4),
                Text(
                  '${route.checkpoints.length} checkpoints',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(
                        route.isActive
                            ? Icons.toggle_on
                            : Icons.toggle_off,
                        color: route.isActive ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(route.isActive ? 'Deactivate' : 'Activate'),
                    ],
                  ),
                  onTap: () => Future.delayed(
                    Duration.zero,
                        () => _toggleRouteStatus(route),
                  ),
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                  onTap: () async {
                    await Future.delayed(Duration.zero);
                    if (mounted) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateRouteScreen(
                            routeToEdit: route,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadRoutes();
                      }
                    }
                  },
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                  onTap: () => Future.delayed(
                    Duration.zero,
                        () => _deleteRoute(route),
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RouteDetailScreen(route: route),
                ),
              );
            },
          ),
          if (route.checkpoints.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Checkpoint Order:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: route.checkpoints.map((cp) {
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            '${cp.order}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        label: Text(
                          cp.checkpointName,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.blue[50],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}