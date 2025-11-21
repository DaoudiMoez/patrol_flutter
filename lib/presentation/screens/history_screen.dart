import 'package:flutter/material.dart';
import 'package:patrol_management/core/constants/app_colors.dart';
import 'package:patrol_management/core/utils/preferences.dart';
import 'package:patrol_management/data/services/patrol_api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final PatrolApiService _apiService = PatrolApiService();
  List<dynamic> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final apiKey = Preferences.getApiKey();
      if (apiKey == null) return;

      final sessions = await _apiService.getSessions(apiKey, limit: 50);

      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading sessions: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patrol History'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No patrol history yet',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadSessions,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _sessions.length,
          itemBuilder: (context, index) {
            final session = _sessions[index];
            final name = session['name'] ?? 'Unknown';
            final state = session['state'] ?? 'unknown';
            final startTime = session['start_time'] ?? '';
            final eventCount = session['event_count'] ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: state == 'finished'
                      ? AppColors.success
                      : AppColors.warning,
                  child: Icon(
                    state == 'finished'
                        ? Icons.check_circle
                        : Icons.pending,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Checkpoints: $eventCount'),
                    if (startTime.isNotEmpty)
                      Text('Started: ${startTime.substring(0, 19)}'),
                    Text(
                      state == 'finished' ? 'Completed' : 'In Progress',
                      style: TextStyle(
                        color: state == 'finished'
                            ? AppColors.success
                            : AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        ),
      ),
    );
  }
}