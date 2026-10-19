import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'dart:io';

/// Comprehensive permission management service
/// Handles all device permissions needed by the app
class PermissionService {
  /// Check if notification permission is granted
  static Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Request notification permission
  static Future<bool> requestNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.request();
    
    if (status.isDenied || status.isPermanentlyDenied) {
      _showPermissionDialog(
        context,
        'Notification Permission Required',
        'This app needs notification permission to send you reminders for check-in/check-out.',
      );
      return false;
    }
    
    return status.isGranted;
  }

  /// Check if camera permission is granted
  static Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Request camera permission
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.request();
    
    if (status.isDenied || status.isPermanentlyDenied) {
      _showPermissionDialog(
        context,
        'Camera Permission Required',
        'This app needs camera permission to capture photos for attendance.',
      );
      return false;
    }
    
    return status.isGranted;
  }

  /// Check if storage permission is granted
  static Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      return status.isGranted;
    }
    return true; // iOS doesn't need explicit storage permission
  }

  /// Request storage permission
  static Future<bool> requestStoragePermission(BuildContext context) async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      
      if (status.isDenied || status.isPermanentlyDenied) {
        _showPermissionDialog(
          context,
          'Storage Permission Required',
          'This app needs storage permission to save reports and export data.',
        );
        return false;
      }
      
      return status.isGranted;
    }
    return true;
  }

  /// Check if microphone permission is granted
  static Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Request microphone permission
  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    final status = await Permission.microphone.request();
    
    if (status.isDenied || status.isPermanentlyDenied) {
      _showPermissionDialog(
        context,
        'Microphone Permission Required',
        'This app needs microphone permission for voice notes.',
      );
      return false;
    }
    
    return status.isGranted;
  }

  /// Check if location permission is granted
  static Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Request location permission
  static Future<bool> requestLocationPermission(BuildContext context) async {
    final status = await Permission.location.request();
    
    if (status.isDenied || status.isPermanentlyDenied) {
      _showPermissionDialog(
        context,
        'Location Permission Required',
        'This app needs location permission to verify your check-in location.',
      );
      return false;
    }
    
    return status.isGranted;
  }

  /// Check if phone permission is granted (Android only)
  static Future<bool> hasPhonePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.phone.status;
      return status.isGranted;
    }
    return true;
  }

  /// Request phone permission (Android only)
  static Future<bool> requestPhonePermission(BuildContext context) async {
    if (Platform.isAndroid) {
      final status = await Permission.phone.request();
      
      if (status.isDenied || status.isPermanentlyDenied) {
        _showPermissionDialog(
          context,
          'Phone Permission Required',
          'This app needs phone permission to handle calls during work hours.',
        );
        return false;
      }
      
      return status.isGranted;
    }
    return true;
  }

  /// Request all essential permissions at once
  static Future<Map<String, bool>> requestAllPermissions(BuildContext context) async {
    return {
      'notification': await requestNotificationPermission(context),
      'camera': await requestCameraPermission(context),
      'storage': await requestStoragePermission(context),
      'location': await requestLocationPermission(context),
    };
  }

  /// Get status of all permissions
  static Future<Map<String, PermissionStatus>> getAllPermissionStatus() async {
    return {
      'notification': await Permission.notification.status,
      'camera': await Permission.camera.status,
      'storage': Platform.isAndroid ? await Permission.storage.status : PermissionStatus.granted,
      'microphone': await Permission.microphone.status,
      'location': await Permission.location.status,
      'phone': Platform.isAndroid ? await Permission.phone.status : PermissionStatus.granted,
    };
  }

  /// Open app settings
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  /// Show permission dialog
  static void _showPermissionDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFFB0B0B0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFB0B0B0))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F6EF7),
            ),
            child: const Text('Open Settings', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Check if permission is permanently denied
  static Future<bool> isPermissionPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }
}
