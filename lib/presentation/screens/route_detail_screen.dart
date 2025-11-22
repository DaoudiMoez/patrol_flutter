import 'package:flutter/material.dart';
import 'package:patrol_management/core/constants/app_colors.dart';
import 'package:patrol_management/data/models/route_config.dart';

class RouteDetailScreen extends StatelessWidget {
  final RouteConfig route;

  const RouteDetailScreen({Key? key, required this.route}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(route.name),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              route.isActive ? Icons.toggle_on : Icons.toggle_off,
              color: route.isActive ? Colors.greenAccent : Colors.white,
            ),
            onPressed: () {
              // Can add toggle functionality here
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Route info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Route Information',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    'Status',
                    route.isActive ? 'Active' : 'Inactive',
                    route.isActive ? Colors.green : Colors.grey,
                  ),
                  _buildInfoRow(
                    'Total Checkpoints',
                    '${route.checkpoints.length}',
                  ),
                  _buildInfoRow(
                    'Required Checkpoints',
                    '${route.checkpoints.where((cp) => cp.isRequired).length}',
                  ),
                  if (route.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(route.description),
                  ],
                  if (route.createdAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Created: ${route.createdAt!.toString().substring(0, 16)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Checkpoint list
          Text(
            'Checkpoint Sequence',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...route.checkpoints.asMap().entries.map((entry) {
            final index = entry.key;
            final checkpoint = entry.value;
            final isLast = index == route.checkpoints.length - 1;

            return Column(
              children: [
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                      checkpoint.isRequired ? AppColors.error : AppColors.primary,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      checkpoint.checkpointName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      checkpoint.isRequired ? 'Required' : 'Optional',
                      style: TextStyle(
                        color: checkpoint.isRequired
                            ? AppColors.error
                            : AppColors.primary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(Icons.location_on),
                  ),
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Row(
                      children: [
                        Container(
                          width: 2,
                          height: 20,
                          color: Colors.blue[300],
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_downward,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}