import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:patrol_management/core/constants/app_colors.dart';
import 'package:patrol_management/core/utils/preferences.dart';
import 'package:patrol_management/core/api/dio_client.dart';
import 'package:patrol_management/data/services/patrol_api_service.dart';
import 'package:patrol_management/presentation/screens/dashboard_screen.dart';
import 'package:patrol_management/presentation/screens/admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final PatrolApiService _apiService = PatrolApiService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _selectedUser;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkExistingLogin();
    });
    _loadUsers();
  }

  Future<void> _checkExistingLogin() async {
    final apiKey = Preferences.getApiKey();
    final isAdmin = await DioClient.isAdmin();

    if (apiKey != null && apiKey.isNotEmpty && mounted) {
      // Navigate to appropriate screen based on role
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => isAdmin
              ? const AdminDashboardScreen()
              : const DashboardScreen(),
        ),
      );
    }
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _apiService.getUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load users: $e';
        });
      }
    }
  }

  Future<void> _login() async {
    if (_selectedUser == null) {
      setState(() {
        _errorMessage = 'Please select a user';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiKey = _selectedUser!['api_key'] as String;
      final isAdmin = _selectedUser!['is_admin'] == true;

      print('===== LOGIN ATTEMPT =====');
      print('Selected User: ${_selectedUser!['name']}');
      print('User ID: ${_selectedUser!['id']}');
      print('is_admin: $isAdmin');
      print('API Key: ${apiKey.substring(0, 10)}...');

      // Save API key
      await Preferences.saveApiKey(apiKey);

      // Generate device ID if not exists
      String? deviceId = Preferences.getDeviceId();
      if (deviceId == null) {
        deviceId = 'DEVICE_${DateTime.now().millisecondsSinceEpoch}';
        await Preferences.saveDeviceId(deviceId);
      }

      // Save session info (using API key as session placeholder)
      await DioClient.saveSession(
        _selectedUser!['id'] ?? 0,
        apiKey, // Using API key as session ID
        _selectedUser!['name'],
        isAdmin: isAdmin,
      );

      print('✅ Session saved successfully');

      // Small delay to ensure preferences are saved
      await Future.delayed(const Duration(milliseconds: 200));

      if (mounted) {
        print('🔄 Navigating to: ${isAdmin ? "AdminDashboard" : "Dashboard"}');

        // Navigate to appropriate screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => isAdmin
                ? const AdminDashboardScreen()
                : const DashboardScreen(),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Login error: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Login failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.security,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Patrol App',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Guard Patrol Management',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),

                // User Selection Card
                Card(
                  elevation: 2,
                  color: AppColors.cardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Select Your Name',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Loading or User List
                        if (_isLoading && _users.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_errorMessage != null)
                          Column(
                            children: [
                              Text(
                                _errorMessage!,
                                style: TextStyle(color: AppColors.error),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: _loadUsers,
                                child: const Text('Retry'),
                              ),
                            ],
                          )
                        else if (_users.isEmpty)
                            const Text(
                              'No users found',
                              textAlign: TextAlign.center,
                            )
                          else
                          // User Grid
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.2,
                              ),
                              itemCount: _users.length,
                              itemBuilder: (context, index) {
                                final user = _users[index];
                                final isSelected = _selectedUser == user;
                                final isAdmin = user['is_admin'] == true;

                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedUser = user;
                                      _errorMessage = null;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withOpacity(0.1)
                                          : Colors.grey[100],
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.grey[300]!,
                                        width: isSelected ? 3 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Stack(
                                          children: [
                                            CircleAvatar(
                                              radius: 30,
                                              backgroundColor: isSelected
                                                  ? AppColors.primary
                                                  : Colors.grey[400],
                                              child: Text(
                                                user['name'][0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            // Admin badge
                                            if (isAdmin)
                                              Positioned(
                                                right: 0,
                                                bottom: 0,
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.admin_panel_settings,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          user['name'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: AppColors.textPrimary,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (isAdmin)
                                          Text(
                                            'Admin',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.orange[700],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                        const SizedBox(height: 24),

                        // Login Button
                        ElevatedButton(
                          onPressed:
                          (_isLoading || _selectedUser == null) ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                              : Text(
                            _selectedUser != null &&
                                _selectedUser!['is_admin'] == true
                                ? 'Login as Admin'
                                : 'Start Patrol',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}