import 'package:flutter/material.dart';
import '../../data/services/admin_api_service.dart';
import '../../data/models/route_config.dart';
import '../../data/models/checkpoint.dart';
import '../../core/utils/logger.dart';

class CreateRouteScreen extends StatefulWidget {
  final RouteConfig? routeToEdit;

  const CreateRouteScreen({Key? key, this.routeToEdit}) : super(key: key);

  @override
  State<CreateRouteScreen> createState() => _CreateRouteScreenState();
}

class _CreateRouteScreenState extends State<CreateRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final AdminApiService _adminApiService = AdminApiService();

  List<Checkpoint> _availableCheckpoints = [];
  List<CheckpointOrderRequest> _selectedCheckpoints = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCheckpoints();

    if (widget.routeToEdit != null) {
      _nameController.text = widget.routeToEdit!.name;
      _descriptionController.text = widget.routeToEdit!.description;
      _selectedCheckpoints = widget.routeToEdit!.checkpoints
          .map((cp) => CheckpointOrderRequest(
        checkpointId: cp.checkpointId,
        order: cp.order,
        isRequired: cp.isRequired,
      ))
          .toList();
    }
  }

  Future<void> _loadCheckpoints() async {
    setState(() => _isLoading = true);
    try {
      final checkpoints = await _adminApiService.getAllCheckpoints();
      setState(() {
        _availableCheckpoints = checkpoints;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading checkpoints', e);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading checkpoints: $e')),
        );
      }
    }
  }

  Future<void> _saveRoute() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCheckpoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one checkpoint')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final request = CreateRouteRequest(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        checkpoints: _selectedCheckpoints,
      );

      if (widget.routeToEdit != null) {
        await _adminApiService.updateRoute(widget.routeToEdit!.id, request);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Route updated successfully')),
          );
        }
      } else {
        await _adminApiService.createRoute(request);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Route created successfully')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      AppLogger.error('Error saving route', e);
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving route: $e')),
        );
      }
    }
  }

  void _addCheckpoint() {
    showDialog(
      context: context,
      builder: (context) => _CheckpointSelectionDialog(
        availableCheckpoints: _availableCheckpoints,
        selectedCheckpointIds: _selectedCheckpoints
            .map((cp) => cp.checkpointId)
            .toList(),
        onCheckpointSelected: (checkpoint) {
          setState(() {
            _selectedCheckpoints.add(CheckpointOrderRequest(
              checkpointId: checkpoint.id,
              order: _selectedCheckpoints.length + 1,
            ));
          });
        },
      ),
    );
  }

  void _removeCheckpoint(int index) {
    setState(() {
      _selectedCheckpoints.removeAt(index);
      // Reorder remaining checkpoints
      for (int i = 0; i < _selectedCheckpoints.length; i++) {
        _selectedCheckpoints[i] = CheckpointOrderRequest(
          checkpointId: _selectedCheckpoints[i].checkpointId,
          order: i + 1,
          isRequired: _selectedCheckpoints[i].isRequired,
        );
      }
    });
  }

  void _reorderCheckpoints(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _selectedCheckpoints.removeAt(oldIndex);
      _selectedCheckpoints.insert(newIndex, item);

      // Update orders
      for (int i = 0; i < _selectedCheckpoints.length; i++) {
        _selectedCheckpoints[i] = CheckpointOrderRequest(
          checkpointId: _selectedCheckpoints[i].checkpointId,
          order: i + 1,
          isRequired: _selectedCheckpoints[i].isRequired,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeToEdit != null ? 'Edit Route' : 'Create Route'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveRoute,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Route Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a route name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Checkpoint Order',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addCheckpoint,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedCheckpoints.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No checkpoints added',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap "Add" to select checkpoints',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedCheckpoints.length,
                onReorder: _reorderCheckpoints,
                itemBuilder: (context, index) {
                  final checkpointOrder = _selectedCheckpoints[index];
                  final checkpoint = _availableCheckpoints.firstWhere(
                        (cp) => cp.id == checkpointOrder.checkpointId,
                  );

                  return Card(
                    key: ValueKey(checkpointOrder.checkpointId),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.drag_handle),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      title: Text(checkpoint.name),
                      //subtitle: Text(checkpoint.description),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: checkpointOrder.isRequired,
                            onChanged: (value) {
                              setState(() {
                                _selectedCheckpoints[index] =
                                    CheckpointOrderRequest(
                                      checkpointId: checkpointOrder.checkpointId,
                                      order: checkpointOrder.order,
                                      isRequired: value ?? true,
                                    );
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeCheckpoint(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class _CheckpointSelectionDialog extends StatelessWidget {
  final List<Checkpoint> availableCheckpoints;
  final List<int> selectedCheckpointIds;
  final Function(Checkpoint) onCheckpointSelected;

  const _CheckpointSelectionDialog({
    required this.availableCheckpoints,
    required this.selectedCheckpointIds,
    required this.onCheckpointSelected,
  });

  @override
  Widget build(BuildContext context) {
    final unselectedCheckpoints = availableCheckpoints
        .where((cp) => !selectedCheckpointIds.contains(cp.id))
        .toList();

    return AlertDialog(
      title: const Text('Select Checkpoint'),
      content: SizedBox(
        width: double.maxFinite,
        child: unselectedCheckpoints.isEmpty
            ? const Padding(
          padding: EdgeInsets.all(16),
          child: Text('All checkpoints have been added'),
        )
            : ListView.builder(
          shrinkWrap: true,
          itemCount: unselectedCheckpoints.length,
          itemBuilder: (context, index) {
            final checkpoint = unselectedCheckpoints[index];
            return ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(checkpoint.name),
              //subtitle: Text(checkpoint.description),
              onTap: () {
                onCheckpointSelected(checkpoint);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}