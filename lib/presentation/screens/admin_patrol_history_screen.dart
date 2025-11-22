import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:patrol_management/core/constants/app_colors.dart';
import 'package:patrol_management/core/utils/logger.dart';
import 'package:patrol_management/data/services/admin_api_service.dart';
import 'package:patrol_management/data/models/patrol_history.dart';
import 'package:patrol_management/presentation/screens/patrol_history_detail_screen.dart';

class AdminPatrolHistoryScreen extends StatefulWidget {
  const AdminPatrolHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AdminPatrolHistoryScreen> createState() =>
      _AdminPatrolHistoryScreenState();
}

class _AdminPatrolHistoryScreenState extends State<AdminPatrolHistoryScreen> {
  final AdminApiService _adminApiService = AdminApiService();
  List<PatrolHistory> _patrols = [];
  bool _isLoading = true;

  // Filters
  String? _selectedStatus;
  DateTimeRange? _dateRange;
  int _currentPage = 1;
  final int _perPage = 20;

  final List<String> _statusOptions = [
    'all',
    'completed',
    'finished',
    'in_progress',
    'active',
    'incomplete',
  ];

  @override
  void initState() {
    super.initState();
    _loadPatrolHistory();
  }

  Future<void> _loadPatrolHistory() async {
    setState(() => _isLoading = true);
    try {
      final patrols = await _adminApiService.getAllPatrolHistory(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        page: _currentPage,
        perPage: _perPage,
      );

      setState(() {
        _patrols = patrols;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading patrol history', e);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading patrol history: $e')),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _currentPage = 1;
      });
      _loadPatrolHistory();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _dateRange = null;
      _currentPage = 1;
    });
    _loadPatrolHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patrol History'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatrolHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters bar
          if (_selectedStatus != null || _dateRange != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_selectedStatus != null)
                          Chip(
                            label: Text('Status: $_selectedStatus'),
                            onDeleted: () {
                              setState(() => _selectedStatus = null);
                              _loadPatrolHistory();
                            },
                          ),
                        if (_dateRange != null)
                          Chip(
                            label: Text(
                              '${DateFormat('MMM dd').format(_dateRange!.start)} - '
                                  '${DateFormat('MMM dd').format(_dateRange!.end)}',
                            ),
                            onDeleted: () {
                              setState(() => _dateRange = null);
                              _loadPatrolHistory();
                            },
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),

          // Patrol list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _patrols.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _loadPatrolHistory,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _patrols.length,
                itemBuilder: (context, index) {
                  final patrol = _patrols[index];
                  return _buildPatrolCard(patrol);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No patrol history found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatrolCard(PatrolHistory patrol) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatrolHistoryDetailScreen(patrol: patrol),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getStatusColor(patrol.status),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patrol.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy HH:mm')
                              .format(patrol.startTime),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(patrol.status),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoColumn(
                      Icons.check_circle_outline,
                      'Checkpoints',
                      '${patrol.checkpoints.where((cp) => cp.isCompleted).length}/${patrol.checkpoints.length}',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoColumn(
                      Icons.access_time,
                      'Duration',
                      patrol.formattedDuration,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoColumn(
                      Icons.straighten,
                      'Distance',
                      patrol.formattedDistance,
                    ),
                  ),
                ],
              ),
              if (patrol.mapImageUrl != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.map, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Map available',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'finished':
        return Colors.green;
      case 'in_progress':
      case 'active':
        return Colors.blue;
      case 'incomplete':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Patrols'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _statusOptions.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedStatus = value);
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Date Range',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _selectDateRange();
              },
              icon: const Icon(Icons.date_range),
              label: Text(
                _dateRange != null
                    ? '${DateFormat('MMM dd').format(_dateRange!.start)} - '
                    '${DateFormat('MMM dd').format(_dateRange!.end)}'
                    : 'Select date range',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _currentPage = 1;
              _loadPatrolHistory();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}