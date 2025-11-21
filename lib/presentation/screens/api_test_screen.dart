import 'package:flutter/material.dart';
import 'package:patrol_management/core/utils/logger.dart';
import 'package:patrol_management/core/utils/preferences.dart';
import 'package:patrol_management/data/models/scan_request.dart';
import 'package:patrol_management/data/models/start_patrol_request.dart';
import 'package:patrol_management/data/models/location_update_request.dart';
import 'package:patrol_management/data/services/patrol_api_service.dart';
import 'package:intl/intl.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final PatrolApiService _apiService = PatrolApiService();
  final TextEditingController _apiKeyController = TextEditingController();

  String _output = 'Ready to test APIs...';
  bool _isLoading = false;
  int? _currentSessionId;

  @override
  void initState() {
    super.initState();
    // Load saved API key
    final savedApiKey = Preferences.getApiKey();
    if (savedApiKey != null) {
      _apiKeyController.text = savedApiKey;
    }

    // Load active session if exists
    _currentSessionId = Preferences.getActiveSessionId();
    if (_currentSessionId != null) {
      _addOutput('Active session found: $_currentSessionId');
    }
  }

  void _addOutput(String text) {
    setState(() {
      _output += '\n\n$text';
    });
    AppLogger.info(text);
  }

  void _clearOutput() {
    setState(() {
      _output = 'Output cleared...';
    });
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      _addOutput('❌ Please enter an API key');
      return;
    }

    await Preferences.saveApiKey(apiKey);
    _addOutput('✅ API Key saved locally');
  }

  Future<void> _testStartPatrol() async {
    setState(() => _isLoading = true);

    try {
      final apiKey = _apiKeyController.text.trim();
      if (apiKey.isEmpty) {
        _addOutput('❌ Please enter an API key first');
        return;
      }

      _addOutput('🚀 Starting patrol...');

      final request = StartPatrolRequest(
        apiKey: apiKey,
        deviceId: 'TEST_DEVICE_001',
        name: 'Test Patrol ${DateFormat('HH:mm:ss').format(DateTime.now())}',
      );

      final response = await _apiService.startPatrol(request);

      if (response.error != null) {
        _addOutput('❌ Error: ${response.error}');
      } else {
        _currentSessionId = response.sessionId;
        await Preferences.saveActiveSessionId(_currentSessionId!);
        _addOutput('✅ Patrol started successfully!');
        _addOutput('Session ID: ${response.sessionId}');
        _addOutput('Session Name: ${response.name}');
      }
    } catch (e) {
      _addOutput('❌ Exception: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testGetCheckpoints() async {
    setState(() => _isLoading = true);

    try {
      final apiKey = _apiKeyController.text.trim();
      if (apiKey.isEmpty) {
        _addOutput('❌ Please enter an API key first');
        return;
      }

      _addOutput('📍 Fetching checkpoints...');

      final checkpoints = await _apiService.getCheckpoints(apiKey);

      _addOutput('✅ Found ${checkpoints.length} checkpoints:');
      for (var checkpoint in checkpoints) {
        _addOutput('  • ${checkpoint.name} (${checkpoint.code})');
      }
    } catch (e) {
      _addOutput('❌ Exception: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testScanCheckpoint() async {
    setState(() => _isLoading = true);

    try {
      final apiKey = _apiKeyController.text.trim();
      if (apiKey.isEmpty) {
        _addOutput('❌ Please enter an API key first');
        return;
      }

      if (_currentSessionId == null) {
        _addOutput('❌ No active session. Start a patrol first!');
        return;
      }

      _addOutput('📷 Scanning checkpoint...');

      final request = ScanRequest(
        apiKey: apiKey,
        sessionId: _currentSessionId!,
        code: 'CHECKPOINT_001', // Change this to match your checkpoint
        scanType: 'qr',
        lat: 36.7538,
        lon: 3.0588,
        accuracy: 5.0,
        timestamp: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        note: 'Test scan from Flutter app',
      );

      final response = await _apiService.scanCheckpoint(request);

      if (response.error != null) {
        _addOutput('❌ Error: ${response.error}');
      } else {
        _addOutput('✅ Checkpoint scanned successfully!');
        _addOutput('Event ID: ${response.eventId}');
      }
    } catch (e) {
      _addOutput('❌ Exception: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testUpdateLocation() async {
    setState(() => _isLoading = true);

    try {
      final apiKey = _apiKeyController.text.trim();
      if (apiKey.isEmpty) {
        _addOutput('❌ Please enter an API key first');
        return;
      }

      if (_currentSessionId == null) {
        _addOutput('❌ No active session. Start a patrol first!');
        return;
      }

      _addOutput('📍 Sending GPS location...');

      final request = LocationUpdateRequest(
        apiKey: apiKey,
        sessionId: _currentSessionId!,
        lat: 36.7539,
        lon: 3.0589,
        accuracy: 4.5,
        timestamp: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      );

      final response = await _apiService.updateLocation(request);

      if (response['error'] != null) {
        _addOutput('❌ Error: ${response['error']}');
      } else {
        _addOutput('✅ Location updated successfully!');
      }
    } catch (e) {
      _addOutput('❌ Exception: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testEndPatrol() async {
    setState(() => _isLoading = true);

    try {
      final apiKey = _apiKeyController.text.trim();
      if (apiKey.isEmpty) {
        _addOutput('❌ Please enter an API key first');
        return;
      }

      if (_currentSessionId == null) {
        _addOutput('❌ No active session to end!');
        return;
      }

      _addOutput('🛑 Ending patrol...');

      final response = await _apiService.endPatrol(apiKey, _currentSessionId!);

      if (response['error'] != null) {
        _addOutput('❌ Error: ${response['error']}');
      } else {
        _addOutput('✅ Patrol ended successfully!');
        await Preferences.clearActiveSessionId();
        _currentSessionId = null;
      }
    } catch (e) {
      _addOutput('❌ Exception: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testGetRoute() async {
    setState(() => _isLoading = true);

    try {
      final apiKey = _apiKeyController.text.trim();
      if (apiKey.isEmpty) {
        _addOutput('❌ Please enter an API key first');
        return;
      }

      if (_currentSessionId == null) {
        _addOutput('❌ No session ID available!');
        return;
      }

      _addOutput('🗺️ Fetching route data...');

      final response = await _apiService.getRoute(apiKey, _currentSessionId!);

      _addOutput('✅ Route data received:');
      _addOutput('Session: ${response['session']}');
      _addOutput('Events: ${response['events']?.length ?? 0}');
      _addOutput('Breadcrumbs: ${response['breadcrumbs']?.length ?? 0}');
    } catch (e) {
      _addOutput('❌ Exception: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testGetSessions() async {
    setState(() => _isLoading = true);

    try {
      final apiKey = _apiKeyController.text.trim();
      if (apiKey.isEmpty) {
        _addOutput('❌ Please enter an API key first');
        return;
      }

      _addOutput('📋 Fetching sessions...');

      final sessions = await _apiService.getSessions(apiKey, limit: 10);

      _addOutput('✅ Found ${sessions.length} sessions:');
      for (var session in sessions) {
        _addOutput('  • ${session['name']} (${session['state']})');
      }
    } catch (e) {
      _addOutput('❌ Exception: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Test Screen'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearOutput,
            tooltip: 'Clear output',
          ),
        ],
      ),
      body: Column(
        children: [
          // API Key Input
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                TextField(
                  controller: _apiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'API Key',
                    border: OutlineInputBorder(),
                    hintText: 'Enter your Odoo API key',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _saveApiKey,
                  child: const Text('Save API Key'),
                ),
                if (_currentSessionId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Active Session: $_currentSessionId',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Test Buttons
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTestButton(
                    'Test 1: Get Checkpoints',
                    _testGetCheckpoints,
                    Colors.blue,
                  ),
                  _buildTestButton(
                    'Test 2: Start Patrol',
                    _testStartPatrol,
                    Colors.green,
                  ),
                  _buildTestButton(
                    'Test 3: Scan Checkpoint',
                    _testScanCheckpoint,
                    Colors.orange,
                  ),
                  _buildTestButton(
                    'Test 4: Update Location (GPS)',
                    _testUpdateLocation,
                    Colors.purple,
                  ),
                  _buildTestButton(
                    'Test 5: Get Route',
                    _testGetRoute,
                    Colors.teal,
                  ),
                  _buildTestButton(
                    'Test 6: End Patrol',
                    _testEndPatrol,
                    Colors.red,
                  ),
                  _buildTestButton(
                    'Test 7: Get Sessions',
                    _testGetSessions,
                    Colors.indigo,
                  ),
                  const SizedBox(height: 20),

                  // Output Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(minHeight: 200),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _output,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading Indicator
          if (_isLoading)
            const LinearProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildTestButton(String label, VoidCallback onPressed, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(label),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}