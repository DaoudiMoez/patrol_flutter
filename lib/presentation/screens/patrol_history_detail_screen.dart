import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:patrol_management/core/constants/app_colors.dart';
import 'package:patrol_management/core/constants/apiConstants.dart';
import 'package:patrol_management/data/models/patrol_history.dart';

class PatrolHistoryDetailScreen extends StatelessWidget {
  final PatrolHistory patrol;

  const PatrolHistoryDetailScreen({Key? key, required this.patrol})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patrol Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Map image if available
          if (patrol.mapImageUrl != null) _buildMapImage(),

          // Patrol info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(context),
                const SizedBox(height: 16),
                _buildStatsCard(context),
                const SizedBox(height: 16),
                _buildCheckpointsCard(context),
                const SizedBox(height: 16),
                _buildTimelineCard(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapImage() {
    return Container(
      height: 300,
      color: Colors.grey[200],
      child: Stack(
        children: [
          Image.network(
            '${ApiConstants.baseUrl}${patrol.mapImageUrl}',
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Map not available'),
                    ],
                  ),
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Patrol Route',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
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
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Patrol #${patrol.id}',
                        style: TextStyle(
                          fontSize: 14,
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
            _buildInfoRow(
              'Start Time',
              DateFormat('MMM dd, yyyy HH:mm:ss').format(patrol.startTime),
            ),
            if (patrol.endTime != null)
              _buildInfoRow(
                'End Time',
                DateFormat('MMM dd, yyyy HH:mm:ss').format(patrol.endTime!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.access_time,
                    'Duration',
                    patrol.formattedDuration,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.straighten,
                    'Distance',
                    patrol.formattedDistance,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.location_on,
                    'Points',
                    '${patrol.locationPoints.length}',
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckpointsCard(BuildContext context) {
    final completedCount =
        patrol.checkpoints.where((cp) => cp.isCompleted).length;
    final totalCount = patrol.checkpoints.length;
    final completionRate =
    totalCount > 0 ? (completedCount / totalCount * 100).toStringAsFixed(0) : '0';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Checkpoints',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '$completedCount/$totalCount ($completionRate%)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: totalCount > 0 ? completedCount / totalCount : 0,
              backgroundColor: Colors.grey[200],
              color: completionRate == '100' ? Colors.green : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Checkpoint Timeline',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ...patrol.checkpoints.map((checkpoint) {
              return _buildTimelineItem(checkpoint);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(PatrolCheckpointHistory checkpoint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: checkpoint.isCompleted ? Colors.green : Colors.grey[300],
                  border: Border.all(
                    color: checkpoint.isCompleted ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                ),
                child: checkpoint.isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              if (patrol.checkpoints.last != checkpoint)
                Container(
                  width: 2,
                  height: 40,
                  color: Colors.grey[300],
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkpoint.checkpointName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  checkpoint.scannedAt != null
                      ? DateFormat('HH:mm:ss').format(checkpoint.scannedAt!)
                      : 'Not scanned',
                  style: TextStyle(
                    fontSize: 12,
                    color: checkpoint.isCompleted
                        ? Colors.green[700]
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
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
}