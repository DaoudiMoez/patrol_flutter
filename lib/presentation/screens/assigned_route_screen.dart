import 'package:flutter/material.dart';
import 'package:patrol_management/core/constants/app_colors.dart';

class AssignedRouteScreen extends StatelessWidget {
  final Map<String, dynamic> routeData;

  const AssignedRouteScreen({Key? key, required this.routeData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final checkpoints = routeData['checkpoints'] as List? ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your Route'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Route Info Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.route, color: AppColors.primary, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              routeData['name'] ?? 'Patrol Route',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (routeData['description'] != null &&
                                routeData['description'].toString().isNotEmpty)
                              Text(
                                routeData['description'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        '${checkpoints.length} Checkpoints',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Follow this route and scan each checkpoint in order',
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Checkpoint List
          Text(
            'Checkpoint Sequence',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...checkpoints.asMap().entries.map((entry) {
            final index = entry.key;
            final checkpoint = entry.value;
            final isLast = index == checkpoints.length - 1;
            final isRequired = checkpoint['is_required'] ?? true;

            return Column(
              children: [
                Card(
                  elevation: 1,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isRequired ? AppColors.primary : Colors.grey,
                      child: Text(
                        '${checkpoint['sequence']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      checkpoint['checkpoint_name'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Code: ${checkpoint['checkpoint_code'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          isRequired ? '⚠️ Required' : 'Optional',
                          style: TextStyle(
                            fontSize: 11,
                            color: isRequired ? AppColors.error : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(
                      Icons.qr_code_scanner,
                      color: AppColors.primary,
                    ),
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
                        Icon(
                          Icons.arrow_downward,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }).toList(),

          const SizedBox(height: 24),

          // Start Button
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true); // Return true to indicate ready to start
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Start Patrol',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}