import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_model.dart';
import 'auth_provider.dart';
import 'schedule_provider.dart';

// ─── Tick every second so live timers update ──────────────────────────────────
final _tickProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (i) => i);
});

// ─── Today's attendance stream from Firestore ─────────────────────────────────
final todayAttendanceProvider = StreamProvider<AttendanceModel?>((ref) {
  final userId = ref.watch(currentUserProvider)?.uid;
  if (userId == null) return Stream.value(null);
  return ref.watch(firestoreServiceProvider).streamTodayAttendance(userId);
});

// ─── Timestamp-based ODC seconds ─────────────────────────────────────────────
/// Total ODC elapsed in SECONDS.
/// Source of truth: stored timestamps.
/// The tick provider only triggers a rebuild so the UI updates — the value
/// itself is always derived from startTime → now (or endTime).
final currentODCSecondsProvider = Provider<int>((ref) {
  ref.watch(_tickProvider); // re-evaluate every second
  final attendanceAsync = ref.watch(todayAttendanceProvider);

  return attendanceAsync.when(
    data: (attendance) {
      if (attendance == null) return 0;
      final sessions = attendance.sessions.where((s) => s.type == 'odc');
      return sessions.fold<int>(0, (sum, session) {
        if (session.endTime != null) {
          // Completed session — use its persisted duration (minutes) × 60
          return sum + session.duration * 60;
        } else {
          // Active session — compute from real wall-clock timestamps
          return sum +
              DateTime.now().difference(session.startTime).inSeconds;
        }
      });
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Total ODC in MINUTES (floored from seconds for display).
final currentODCTimeProvider = Provider<int>((ref) {
  return ref.watch(currentODCSecondsProvider) ~/ 60;
});

// ─── Timestamp-based Break seconds ────────────────────────────────────────────
final currentBreakSecondsProvider = Provider<int>((ref) {
  ref.watch(_tickProvider);
  final attendanceAsync = ref.watch(todayAttendanceProvider);

  return attendanceAsync.when(
    data: (attendance) {
      if (attendance == null) return 0;
      final sessions = attendance.sessions.where((s) => s.type == 'break');
      return sessions.fold<int>(0, (sum, session) {
        if (session.endTime != null) {
          return sum + session.duration * 60;
        } else {
          return sum +
              DateTime.now().difference(session.startTime).inSeconds;
        }
      });
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final currentBreakTimeProvider = Provider<int>((ref) {
  return ref.watch(currentBreakSecondsProvider) ~/ 60;
});

// ─── Schedule-aware completion ────────────────────────────────────────────────
final completionPercentageProvider = Provider<double>((ref) {
  final odcTime = ref.watch(currentODCTimeProvider);
  final scheduleAsync = ref.watch(activeScheduleProvider);
  final goal = scheduleAsync.whenOrNull(data: (s) => s?.requiredOdcMinutes) ??
      _userGoal(ref);
  return (odcTime / goal) * 100;
});

final remainingODCProvider = Provider<int>((ref) {
  final odcTime = ref.watch(currentODCTimeProvider);
  final scheduleAsync = ref.watch(activeScheduleProvider);
  final goal = scheduleAsync.whenOrNull(data: (s) => s?.requiredOdcMinutes) ??
      _userGoal(ref);
  final remaining = goal - odcTime;
  return remaining > 0 ? remaining : 0;
});

final remainingBreakProvider = Provider<int>((ref) {
  final breakTime = ref.watch(currentBreakTimeProvider);
  final scheduleAsync = ref.watch(activeScheduleProvider);
  final limit =
      scheduleAsync.whenOrNull(data: (s) => s?.allowedBreakMinutes) ??
          _userBreakLimit(ref);
  final remaining = limit - breakTime;
  return remaining > 0 ? remaining : 0;
});

// ─── Status flags ──────────────────────────────────────────────────────────────
final isActiveProvider = Provider<bool>((ref) {
  final attendanceAsync = ref.watch(todayAttendanceProvider);
  return attendanceAsync.when(
    data: (attendance) => attendance?.isActive ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

final isOnBreakProvider = Provider<bool>((ref) {
  final attendanceAsync = ref.watch(todayAttendanceProvider);
  return attendanceAsync.when(
    data: (attendance) {
      if (attendance == null || attendance.sessions.isEmpty) return false;
      final last = attendance.sessions.last;
      return last.type == 'break' && last.endTime == null;
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Timestamp when the current break started (null if not on break).
final breakStartTimeProvider = Provider<DateTime?>((ref) {
  final attendanceAsync = ref.watch(todayAttendanceProvider);
  return attendanceAsync.when(
    data: (attendance) {
      if (attendance == null || attendance.sessions.isEmpty) return null;
      final last = attendance.sessions.last;
      if (last.type == 'break' && last.endTime == null) return last.startTime;
      return null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Current break duration derived from breakStartTime (not from a timer).
final currentBreakDurationProvider = Provider<Duration>((ref) {
  ref.watch(_tickProvider); // tick drives rebuild
  final start = ref.watch(breakStartTimeProvider);
  if (start == null) return Duration.zero;
  return DateTime.now().difference(start);
});

// ─── Helpers ──────────────────────────────────────────────────────────────────
int _userGoal(Ref ref) {
  return ref.watch(userProfileProvider).whenOrNull(data: (u) => u?.dailyGoal) ??
      480;
}

int _userBreakLimit(Ref ref) {
  return ref.watch(userProfileProvider).whenOrNull(data: (u) => u?.breakLimit) ??
      60;
}

// ─── Auto shift-end watcher ───────────────────────────────────────────────────
/// Watches the clock every minute and auto-closes the shift when the
/// schedule's endTime is reached (e.g. 10:00 PM for Schedule A).
final autoShiftEndProvider = Provider<void>((ref) {
  // Re-evaluate every minute (the tick fires every second; we throttle via
  // the minute check inside).
  ref.watch(_tickProvider);

  final userId = ref.watch(currentUserProvider)?.uid;
  if (userId == null) return;

  final isActive = ref.watch(isActiveProvider);
  if (!isActive) return;

  final scheduleAsync = ref.watch(activeScheduleProvider);
  scheduleAsync.whenData((schedule) {
    if (schedule == null) return;

    final now = DateTime.now();
    final parts = schedule.endTime.split(':');
    if (parts.length < 2) return;
    final endH = int.tryParse(parts[0]) ?? 22;
    final endM = int.tryParse(parts[1]) ?? 0;

    // Trigger only once: when now >= shiftEnd (within a 1-minute window)
    final shiftEnd = DateTime(now.year, now.month, now.day, endH, endM);
    if (now.isAfter(shiftEnd) || now.isAtSameMomentAs(shiftEnd)) {
      // Fire-and-forget — don't await inside a provider
      ref.read(firestoreServiceProvider)
          .autoEndShiftIfNeeded(userId, schedule);
    }
  });
});
