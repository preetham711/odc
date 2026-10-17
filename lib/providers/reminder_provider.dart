import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/hive_service.dart';
import '../models/reminder_settings.dart';
import '../notifications/notification_service.dart';
import 'attendance_provider.dart';

final reminderSettingsProvider =
    StateNotifierProvider<ReminderSettingsNotifier, ReminderSettings>((ref) {
  return ReminderSettingsNotifier();
});

class ReminderSettingsNotifier extends StateNotifier<ReminderSettings> {
  ReminderSettingsNotifier() : super(const ReminderSettings()) {
    _load();
  }

  void _load() {
    if (kIsWeb) return; // Hive not available on web — use defaults
    try {
      final box = HiveService.getSettingsBox();
      state = ReminderSettings.fromBox(box);
    } catch (_) {}
  }

  Future<void> update(ReminderSettings settings) async {
    state = settings;
    if (kIsWeb) return;
    try {
      final box = HiveService.getSettingsBox();
      await settings.saveToBox(box);
    } catch (_) {}
  }

  Future<void> toggle(bool enabled) =>
      update(state.copyWith(enabled: enabled));

  Future<void> setInterval(int minutes) =>
      update(state.copyWith(intervalMinutes: minutes));

  Future<void> setVibration(bool v) => update(state.copyWith(vibration: v));

  Future<void> setRepeat(bool r) =>
      update(state.copyWith(repeatUntilReturn: r));

  Future<void> setMaxDuration(int minutes) =>
      update(state.copyWith(maxDurationMinutes: minutes));

  Future<void> setQuietHours(bool enabled, int start, int end) =>
      update(state.copyWith(
          quietHoursEnabled: enabled, quietStart: start, quietEnd: end));
}

// ── Break elapsed provider ─────────────────────────────────────────────────
//
// Ticks every second.  Source of truth priority:
//   1. NotificationService._breakStartTime (in-memory, set when startBreak is tapped)
//   2. The last open break session from the Firestore attendance stream
//      (covers app restarts while on break)

final _breakTickProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (i) => i);
});

final breakElapsedProvider = Provider<Duration>((ref) {
  ref.watch(_breakTickProvider);

  // Priority 1 — in-memory start time (most accurate, no Firestore lag)
  final inMemory = NotificationService().breakStartTime;
  if (inMemory != null) {
    return DateTime.now().difference(inMemory);
  }

  // Priority 2 — derive from Firestore attendance stream so the live panel
  // still shows correct data after an app restart.
  final attendanceAsync = ref.watch(todayAttendanceProvider);
  return attendanceAsync.when(
    data: (attendance) {
      if (attendance == null || attendance.sessions.isEmpty) {
        return Duration.zero;
      }
      final last = attendance.sessions.last;
      if (last.type == 'break' && last.endTime == null) {
        return DateTime.now().difference(last.startTime);
      }
      return Duration.zero;
    },
    loading: () => Duration.zero,
    error: (_, __) => Duration.zero,
  );
});

/// Time remaining until the next reminder fires.
/// Returns null when reminders are disabled or no break is active.
final nextReminderInProvider = Provider<Duration?>((ref) {
  ref.watch(_breakTickProvider);
  final settings = ref.watch(reminderSettingsProvider);
  if (!settings.enabled) return null;

  final elapsed = ref.watch(breakElapsedProvider);
  if (elapsed == Duration.zero) return null;

  final intervalSecs = settings.intervalMinutes * 60;
  if (intervalSecs <= 0) return null;

  final secondsIntoInterval = elapsed.inSeconds % intervalSecs;
  final secondsUntilNext = intervalSecs - secondsIntoInterval;

  return Duration(seconds: secondsUntilNext);
});
