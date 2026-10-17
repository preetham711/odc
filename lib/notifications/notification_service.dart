import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../database/hive_service.dart';
import '../models/reminder_settings.dart';
import '../services/firestore_service.dart';

/// Notification IDs
class _NId {
  static const int checkIn      = 1;
  static const int checkOut     = 2;
  static const int breakBase    = 100; // 100–149 cycling
  static const int escalation30 = 200;
  static const int escalation45 = 201;
  static const int escalation60 = 202;
  static const int goalComplete = 10;
}

/// Channel IDs — _v2 suffix forces Android to recreate the channel
/// with correct sound/importance on existing installs.
class _Ch {
  static const String shift       = 'shift_channel_v2';
  static const String reminder    = 'odc_reminder_v2';
  static const String escalation  = 'break_escalation_v2';
  static const String achievement = 'achievement_channel_v2';
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Timer?    _reminderTimer;
  Timer?    _snoozeTimer;
  DateTime? _breakStartTime;
  int       _reminderCount = 0;
  bool      _initialized   = false;
  String?   _currentUserId;

  void setUserId(String? uid) => _currentUserId = uid;

  // ─── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (kIsWeb) return; // flutter_local_notifications is not supported on web
    if (_initialized) return;
    _initialized = true;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundTap,
    );

    await _requestPermissions();
    await _createChannels();
  }

  Future<void> _requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _createChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    // Shift — HIGH importance, default system sound
    await android.createNotificationChannel(const AndroidNotificationChannel(
      _Ch.shift,
      'Shift Notifications',
      description: 'Check-in / check-out events',
      importance: Importance.high,
      playSound: true,
    ));

    // Reminder — MAX so heads-up banner shows and sound plays even in DND.
    // Using the default system notification sound (no custom URI needed —
    // Android will use whatever the user has set for notifications on MAX
    // importance channels, which bypasses silent mode).
    await android.createNotificationChannel(AndroidNotificationChannel(
      _Ch.reminder,
      'ODC Return Reminders',
      description: 'Reminders to return to your desk while on break',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 400, 200, 400, 200, 400]),
    ));

    // Escalation — MAX, same policy
    await android.createNotificationChannel(AndroidNotificationChannel(
      _Ch.escalation,
      'Break Escalations',
      description: 'Warnings when your break exceeds the limit',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 600, 200, 600]),
    ));

    // Achievement — default importance
    await android.createNotificationChannel(const AndroidNotificationChannel(
      _Ch.achievement,
      'Achievements',
      description: 'Goal completions and milestones',
      importance: Importance.defaultImportance,
      playSound: true,
    ));
  }

  // ─── Tap handler ───────────────────────────────────────────────────────────
  void _onTapped(NotificationResponse r) {
    final payload = r.actionId ?? r.payload ?? '';
    if (payload.startsWith('snooze:')) {
      final mins = int.tryParse(payload.split(':').last) ?? 5;
      _startSnooze(mins);
      _logEvent('snoozed', snoozed: true, clicked: true);
    } else if (payload == 'checkin') {
      _logEvent('returned', clicked: true);
      stopBreakReminders();
    }
  }

  // ─── Public shift notifications ────────────────────────────────────────────
  Future<void> showCheckInNotification() async {
    await _plugin.show(
      _NId.checkIn,
      '✅ Shift Started',
      'You\'re checked in. Have a productive shift!',
      _shiftDetails(Importance.high),
    );
  }

  Future<void> showCheckOutNotification(int odcMinutes) async {
    final h = odcMinutes ~/ 60;
    final m = odcMinutes % 60;
    final t = h > 0 ? '${h}h ${m}m' : '${m}m';
    await _plugin.show(
      _NId.checkOut,
      '🏁 Shift Ended',
      'Great work! You clocked $t today.',
      _shiftDetails(Importance.defaultImportance),
    );
  }

  Future<void> showGoalCompleted() async {
    await _plugin.show(
      _NId.goalComplete,
      '🎉 8-Hour Goal Achieved!',
      'Congratulations! You\'ve completed your daily ODC target.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _Ch.achievement,
          'Achievements',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF10B981),
          playSound: true,
        ),
      ),
    );
  }

  // ─── Break Reminder Engine ─────────────────────────────────────────────────

  /// Call when user taps START BREAK / I'M OUT.
  void startBreakReminders() {
    if (kIsWeb) return;
    final s = _loadSettings();
    if (!s.enabled) return;

    _breakStartTime = DateTime.now();
    _reminderCount  = 0;
    _cancelReminderTimers();

    if (s.repeatUntilReturn) {
      _reminderTimer = Timer.periodic(
        Duration(minutes: s.intervalMinutes),
        (_) => _fireReminder(s),
      );
    } else {
      _reminderTimer = Timer(
        Duration(minutes: s.intervalMinutes),
        () => _fireReminder(s),
      );
    }

    _scheduleEscalations(s);
  }

  /// Call IMMEDIATELY when user taps I'M IN / END BREAK.
  void stopBreakReminders() {
    if (kIsWeb) return;
    _cancelReminderTimers();
    _cancelEscalations();
    _breakStartTime = null;
    _reminderCount  = 0;
  }

  void _cancelReminderTimers() {
    _reminderTimer?.cancel();
    _reminderTimer = null;
    _snoozeTimer?.cancel();
    _snoozeTimer = null;
    for (int i = _NId.breakBase; i < _NId.breakBase + 50; i++) {
      _plugin.cancel(i);
    }
  }

  void _cancelEscalations() {
    _plugin.cancel(_NId.escalation30);
    _plugin.cancel(_NId.escalation45);
    _plugin.cancel(_NId.escalation60);
  }

  // ─── Fire one reminder notification ───────────────────────────────────────
  Future<void> _fireReminder(ReminderSettings s) async {
    if (_isQuietHour(s)) return;

    if (s.maxDurationMinutes > 0 && _breakStartTime != null) {
      final elapsed = DateTime.now().difference(_breakStartTime!).inMinutes;
      if (elapsed >= s.maxDurationMinutes) {
        stopBreakReminders();
        return;
      }
    }

    _reminderCount++;
    final elapsed = _breakStartTime != null
        ? DateTime.now().difference(_breakStartTime!).inMinutes
        : 0;

    final id = _NId.breakBase + (_reminderCount % 50);

    await _plugin.show(
      id,
      elapsed > 0 ? '⏰ ODC Reminder · ${elapsed}m outside' : '⏰ ODC Return Reminder',
      'You are still outside the ODC. Return and tap "I\'m IN".',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _Ch.reminder,
          'ODC Return Reminders',
          importance: Importance.max,
          priority: Priority.max,
          // Sound MUST be set at notification level too (channel setting alone
          // is sometimes not honoured on certain Android versions).
          playSound: true,
          enableVibration: s.vibration,
          vibrationPattern: s.vibration
              ? Int64List.fromList([0, 400, 200, 400, 200, 400])
              : null,
          fullScreenIntent: false,
          ticker: 'ODC break reminder',
          styleInformation: BigTextStyleInformation(
            'You are still outside the ODC.\n'
            'Please return to your desk and tap "I\'m IN" to continue'
            ' tracking your ODC hours.'
            '${elapsed > 0 ? '\n⏱ Break time: ${elapsed}m' : ''}',
            contentTitle: elapsed > 0
                ? '⏰ ODC Reminder · ${elapsed}m outside'
                : '⏰ ODC Return Reminder',
          ),
          actions: const [
            AndroidNotificationAction(
              'checkin',
              "I'M IN ✅",
              showsUserInterface: true,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              'snooze:5',
              'Snooze 5 min',
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              'snooze:10',
              'Snooze 10 min',
              cancelNotification: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: 'reminder',
    );

    _logEvent('out', notificationDelivered: true);
  }

  // ─── Snooze ────────────────────────────────────────────────────────────────
  void _startSnooze(int minutes) {
    _reminderTimer?.cancel();
    _reminderTimer = null;

    _snoozeTimer = Timer(Duration(minutes: minutes), () {
      final s = _loadSettings();
      if (s.enabled && _breakStartTime != null) {
        if (s.repeatUntilReturn) {
          _reminderTimer = Timer.periodic(
            Duration(minutes: s.intervalMinutes),
            (_) => _fireReminder(s),
          );
        }
        _fireReminder(s); // fire immediately when snooze ends
      }
    });
  }

  // ─── Escalation notifications ──────────────────────────────────────────────
  Future<void> _scheduleEscalations(ReminderSettings s) async {
    final now = tz.TZDateTime.now(tz.local);
    await _safeSchedule(
      _NId.escalation30,
      now.add(const Duration(minutes: 30)),
      '⚠️ Long Break Alert',
      'Your break has exceeded 30 minutes. Please return to the ODC.',
    );
    await _safeSchedule(
      _NId.escalation45,
      now.add(const Duration(minutes: 45)),
      '⚠️ ODC Target at Risk',
      'Your break is 45 minutes. Your daily ODC target may be affected.',
    );
    await _safeSchedule(
      _NId.escalation60,
      now.add(const Duration(minutes: 60)),
      '🚨 1-Hour Break Limit Reached',
      'You\'ve reached your break limit. Please return immediately.',
    );
  }

  Future<void> _safeSchedule(
      int id, tz.TZDateTime when, String title, String body) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _Ch.escalation,
        'Break Escalations',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 600, 200, 600]),
      ),
      iOS: const DarwinNotificationDetails(
        sound: 'default',
        presentAlert: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        id, title, body, when, details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Exact alarm permission denied — show immediately as fallback
      await _plugin.show(id, title, body, details);
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  bool _isQuietHour(ReminderSettings s) {
    if (!s.quietHoursEnabled) return false;
    final h = DateTime.now().hour;
    if (s.quietStart > s.quietEnd) return h >= s.quietStart || h < s.quietEnd;
    return h >= s.quietStart && h < s.quietEnd;
  }

  ReminderSettings _loadSettings() {
    try {
      return ReminderSettings.fromBox(HiveService.getSettingsBox());
    } catch (_) {
      return const ReminderSettings();
    }
  }

  NotificationDetails _shiftDetails(Importance importance) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _Ch.shift,
        'Shift Notifications',
        importance: importance,
        priority: importance == Importance.high ? Priority.high : Priority.defaultPriority,
        playSound: true,
      ),
    );
  }

  void _logEvent(
    String status, {
    bool notificationDelivered = false,
    bool clicked = false,
    bool snoozed = false,
  }) {
    if (_currentUserId == null) return;
    final elapsed = _breakStartTime != null
        ? DateTime.now().difference(_breakStartTime!).inMinutes
        : 0;
    FirestoreService().logReminderEvent(
      userId: _currentUserId!,
      reminderTime: DateTime.now(),
      breakDurationMinutes: elapsed,
      userStatus: status,
      notificationDelivered: notificationDelivered,
      notificationClicked: clicked,
      snoozed: snoozed,
    );
  }

  // ─── Public getters ────────────────────────────────────────────────────────
  bool get isRemindersActive =>
      _reminderTimer != null && (_reminderTimer?.isActive ?? false);

  /// Break elapsed from the in-memory start time.
  Duration get breakElapsed => _breakStartTime != null
      ? DateTime.now().difference(_breakStartTime!)
      : Duration.zero;

  /// Exposed so reminder_provider can fall back to this instead of Firestore.
  DateTime? get breakStartTime => _breakStartTime;

  Future<void> cancelAll() async {
    stopBreakReminders();
    await _plugin.cancelAll();
  }
}

// Top-level background tap handler — required by flutter_local_notifications
@pragma('vm:entry-point')
void _onBackgroundTap(NotificationResponse response) {
  final payload = response.actionId ?? response.payload ?? '';
  if (payload == 'checkin') {
    NotificationService().stopBreakReminders();
  }
}
