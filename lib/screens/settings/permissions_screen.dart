import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/permission_service.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  Map<String, PermissionStatus> _permissionStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissionStatus();
  }

  Future<void> _loadPermissionStatus() async {
    setState(() => _isLoading = true);
    final status = await PermissionService.getAllPermissionStatus();
    setState(() {
      _permissionStatus = status;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'App Permissions',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadPermissionStatus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4F6EF7),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F6EF7), Color(0xFF6C8FFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.security, color: Colors.white, size: 32),
                          SizedBox(width: 12),
                          Text(
                            'Device Permissions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Manage what the app can access on your device',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Permission cards
                _buildPermissionCard(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  description: 'Get reminders for check-in and check-out',
                  permission: 'notification',
                  onRequest: () => PermissionService.requestNotificationPermission(context),
                ),
                
                _buildPermissionCard(
                  icon: Icons.camera_alt,
                  title: 'Camera',
                  description: 'Capture photos for attendance verification',
                  permission: 'camera',
                  onRequest: () => PermissionService.requestCameraPermission(context),
                ),
                
                _buildPermissionCard(
                  icon: Icons.sd_storage,
                  title: 'Storage',
                  description: 'Save reports and export data to your device',
                  permission: 'storage',
                  onRequest: () => PermissionService.requestStoragePermission(context),
                ),
                
                _buildPermissionCard(
                  icon: Icons.location_on,
                  title: 'Location',
                  description: 'Verify your check-in location',
                  permission: 'location',
                  onRequest: () => PermissionService.requestLocationPermission(context),
                ),
                
                _buildPermissionCard(
                  icon: Icons.mic,
                  title: 'Microphone',
                  description: 'Record voice notes for tasks',
                  permission: 'microphone',
                  onRequest: () => PermissionService.requestMicrophonePermission(context),
                ),
                
                _buildPermissionCard(
                  icon: Icons.phone,
                  title: 'Phone',
                  description: 'Handle calls during work hours (Android only)',
                  permission: 'phone',
                  onRequest: () => PermissionService.requestPhonePermission(context),
                ),

                const SizedBox(height: 24),

                // Request all button
                ElevatedButton(
                  onPressed: () async {
                    await PermissionService.requestAllPermissions(context);
                    _loadPermissionStatus();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F6EF7),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Request All Permissions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Open settings button
                OutlinedButton(
                  onPressed: () => PermissionService.openSettings(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF4F6EF7)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Open System Settings',
                    style: TextStyle(
                      color: Color(0xFF4F6EF7),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF4F6EF7),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: const Text(
                          'Some features may not work properly without the required permissions.',
                          style: TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required String permission,
    required Future<bool> Function() onRequest,
  }) {
    final status = _permissionStatus[permission];
    final isGranted = status?.isGranted ?? false;
    final isDenied = status?.isDenied ?? false;
    final isPermanentlyDenied = status?.isPermanentlyDenied ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted 
              ? const Color(0xFF4CAF50)
              : isPermanentlyDenied
                  ? const Color(0xFFFF5252)
                  : const Color(0xFF2A2A2A),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isGranted
                  ? const Color(0xFF4CAF50).withOpacity(0.2)
                  : const Color(0xFF4F6EF7).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isGranted
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF4F6EF7),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isGranted
                            ? const Color(0xFF4CAF50).withOpacity(0.2)
                            : isPermanentlyDenied
                                ? const Color(0xFFFF5252).withOpacity(0.2)
                                : const Color(0xFFFF9800).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isGranted
                            ? 'Granted'
                            : isPermanentlyDenied
                                ? 'Denied'
                                : 'Not Granted',
                        style: TextStyle(
                          color: isGranted
                              ? const Color(0xFF4CAF50)
                              : isPermanentlyDenied
                                  ? const Color(0xFFFF5252)
                                  : const Color(0xFFFF9800),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isGranted)
            TextButton(
              onPressed: () async {
                final granted = await onRequest();
                _loadPermissionStatus();
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF4F6EF7).withOpacity(0.2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Grant',
                style: TextStyle(
                  color: Color(0xFF4F6EF7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
