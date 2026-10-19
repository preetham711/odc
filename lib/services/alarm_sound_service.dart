import 'package:flutter/material.dart' show Color;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'dart:io';

/// Alarm sound service for check-in/check-out reminders
/// Supports custom alarm sounds from device
class AlarmSoundService {
  static final AlarmSoundService _instance = AlarmSoundService._internal();
  factory AlarmSoundService() => _instance;
  AlarmSoundService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isInitialized = false;
  String? _customSoundPath;

  /// Initialize the alarm sound service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    // Initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  /// Set custom alarm sound path
  void setCustomSound(String soundPath) {
    _customSoundPath = soundPath;
  }

  /// Play alarm sound
  Future<void> playAlarmSound({String? soundPath}) async {
    try {
      final path = soundPath ?? _customSoundPath;
      
      if (path != null && await File(path).exists()) {
        // Play custom sound
        await _audioPlayer.play(DeviceFileSource(path));
      } else {
        // Play default system sound
        await _audioPlayer.play(AssetSource('sounds/default_alarm.mp3'));
      }
    } catch (e) {
      print('Error playing alarm sound: $e');
    }
  }

  /// Stop alarm sound
  Future<void> stopAlarmSound() async {
    await _audioPlayer.stop();
  }

  /// Schedule check-in reminder
  Future<void> scheduleCheckInReminder({
    required DateTime scheduledTime,
    String? customSound,
  }) async {
    await _scheduleNotification(
      id: 1,
      title: '⏰ Time to Check In',
      body: 'Don\'t forget to mark your attendance!',
      scheduledTime: scheduledTime,
      soundPath: customSound,
    );
  }

  /// Schedule check-out reminder
  Future<void> scheduleCheckOutReminder({
    required DateTime scheduledTime,
    String? customSound,
  }) async {
    await _scheduleNotification(
      id: 2,
      title: '⏰ Time to Check Out',
      body: 'Remember to check out before leaving!',
      scheduledTime: scheduledTime,
      soundPath: customSound,
    );
  }

  /// Schedule break reminder
  Future<void> scheduleBreakReminder({
    required DateTime scheduledTime,
    String? customSound,
  }) async {
    await _scheduleNotification(
      id: 3,
      title: '☕ Break Time',
      body: 'Time for a break! Don\'t forget to mark it.',
      scheduledTime: scheduledTime,
      soundPath: customSound,
    );
  }

  /// Schedule custom reminder
  Future<void> scheduleCustomReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? customSound,
  }) async {
    await _scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      soundPath: customSound,
    );
  }

  /// Schedule notification with alarm sound
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? soundPath,
  }) async {
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    final androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Notifications',
      channelDescription: 'Notifications with alarm sounds',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      color: Color(0xFF4F6EF7),
      ledColor: Color(0xFF4F6EF7),
      ledOnMs: 1000,
      ledOffMs: 500,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default_alarm.aiff',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Show immediate alarm notification
  Future<void> showAlarmNotification({
    required int id,
    required String title,
    required String body,
    String? soundPath,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Notifications',
      channelDescription: 'Notifications with alarm sounds',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      color: Color(0xFF4F6EF7),
      fullScreenIntent: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default_alarm.aiff',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(id, title, body, notificationDetails);
    
    // Play alarm sound
    await playAlarmSound(soundPath: soundPath);
  }

  /// Cancel scheduled alarm
  Future<void> cancelAlarm(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all alarms
  Future<void> cancelAllAlarms() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Get all scheduled alarms
  Future<List<PendingNotificationRequest>> getScheduledAlarms() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle navigation based on payload
  }

  /// Set recurring daily alarm
  Future<void> setDailyAlarm({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? soundPath,
  }) async {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
    
    // If time has passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      soundPath: soundPath,
    );
  }

  /// Get available system alarm sounds
  Future<List<String>> getSystemAlarmSounds() async {
    // This would require platform-specific implementation
    // For now, return a list of bundled sounds
    return [
      'Default Alarm',
      'Gentle Wake',
      'Morning Bells',
      'Rise and Shine',
      'Peaceful Wake',
    ];
  }

  /// Dispose resources
  void dispose() {
    _audioPlayer.dispose();
  }
}
