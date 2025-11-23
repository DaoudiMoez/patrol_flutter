import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:patrol_management/core/constants/app_colors.dart';
import 'package:patrol_management/core/utils/preferences.dart';
import 'package:patrol_management/core/utils/logger.dart';
import 'package:patrol_management/data/services/admin_api_service.dart';
import 'package:patrol_management/presentation/screens/route_management_screen.dart';
import 'package:patrol_management/presentation/screens/admin_patrol_history_screen.dart';
import 'package:patrol_management/presentation/screens/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminApiService _adminApiService = AdminApiService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _adminApiService.getDashboardStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading dashboard stats', e);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Preferences.clearAll();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadDashboardStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsCards(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_stats == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3, // ✅ FIXED: Increased from 1.5 to prevent overflow
          children: [
            _buildStatCard(
              'Total Patrols',
              '${_stats!['total_patrols'] ?? 0}',
              Icons.route,
              Colors.blue,
            ),
            _buildStatCard(
              'Active Users',
              '${_stats!['active_users'] ?? 0}',
              Icons.people,
              Colors.green,
            ),
            _buildStatCard(
              'Routes',
              '${_stats!['total_routes'] ?? 0}',
              Icons.map,
              Colors.orange,
            ),
            _buildStatCard(
              'Today',
              '${_stats!['today_patrols'] ?? 0}',
              Icons.today,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12), // ✅ FIXED: Reduced padding from 16 to 12
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color), // ✅ FIXED: Reduced icon size from 32 to 28
            const SizedBox(height: 6), // ✅ FIXED: Reduced spacing from 8 to 6
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 20, // ✅ FIXED: Explicitly set smaller font
              ),
            ),
            const SizedBox(height: 2), // ✅ FIXED: Reduced spacing from 4 to 2
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11, // ✅ FIXED: Reduced font size
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          'Manage Routes',
          'Configure patrol routes and checkpoints',
          Icons.route,
          AppColors.primary,
              () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RouteManagementScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Patrol History',
          'View all patrol records and maps',
          Icons.history,
          AppColors.success,
              () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminPatrolHistoryScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String title,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (_stats == null || _stats!['recent_patrols'] == null) {
      return const SizedBox();
    }

    final recentPatrols = _stats!['recent_patrols'] as List;

    if (recentPatrols.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentPatrols.length,
          itemBuilder: (context, index) {
            final patrol = recentPatrols[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(patrol['status']),
                  child: const Icon(Icons.route, color: Colors.white),
                ),
                title: Text(patrol['user_name']),
                subtitle: Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(
                    DateTime.parse(patrol['start_time']),
                  ),
                ),
                trailing: Chip(
                  label: Text(
                    patrol['status'].toString().toUpperCase(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor:
                  _getStatusColor(patrol['status']).withOpacity(0.2),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'finished':
        return Colors.green;
      case 'in_progress':
      case 'ongoing':
        return Colors.blue;
      case 'incomplete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}