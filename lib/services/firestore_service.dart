import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/attendance_model.dart';
import '../models/note.dart';
import '../models/task.dart';
import '../models/work_schedule.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ─── Offline persistence ───────────────────────────────────────────────────
  Future<void> enableOfflinePersistence() async {
    try {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (_) {}
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Close the last open session (ODC or break) at [endAt] and return updated list.
  List<SessionModel> _closeLastSession(
      List<SessionModel> sessions, DateTime endAt) {
    if (sessions.isEmpty) return sessions;
    final last = sessions.last;
    if (last.endTime != null) return sessions; // already closed
    final result = List<SessionModel>.from(sessions);
    // Duration stored in SECONDS for sub-minute accuracy, then converted to
    // minutes when saved (1 min = 60s, floor). We store raw seconds as duration
    // field on completed sessions so we don't lose the time.
    final durationSec = endAt.difference(last.startTime).inSeconds;
    final durationMin = durationSec ~/ 60; // floor to whole minutes
    result[result.length - 1] = SessionModel(
      id: last.id,
      startTime: last.startTime,
      endTime: endAt,
      type: last.type,
      duration: durationMin,
    );
    return result;
  }

  /// Recalculate stored odcTime / breakTime / completionPercentage from sessions.
  /// Uses [goalMin] and [breakLimitMin] from the active schedule.
  AttendanceModel _recalcTotals(
    AttendanceModel att, {
    required int goalMin,
    required int breakLimitMin,
    required DateTime? checkOut,
    required bool isActive,
  }) {
    int odcSec = 0;
    int breakSec = 0;
    for (final s in att.sessions) {
      if (s.endTime != null) {
        final sec = s.endTime!.difference(s.startTime).inSeconds;
        if (s.type == 'odc') { odcSec += sec; } else { breakSec += sec; }
      } else {
        // Still open — should only happen for the current active session
        final sec = DateTime.now().difference(s.startTime).inSeconds;
        if (s.type == 'odc') { odcSec += sec; } else { breakSec += sec; }
      }
    }
    final odcMin = odcSec ~/ 60;
    final breakMin = breakSec ~/ 60;
    final pct = (odcMin / goalMin * 100).clamp(0.0, double.infinity);
    return att.copyWith(
      checkOut: checkOut,
      isActive: isActive,
      odcTime: odcMin,
      breakTime: breakMin,
      remainingODC: (goalMin - odcMin).clamp(0, goalMin),
      remainingBreak: (breakLimitMin - breakMin).clamp(0, breakLimitMin),
      completionPercentage: pct,
    );
  }

  // ─── Attendance — today ────────────────────────────────────────────────────

  Future<AttendanceModel?> getTodayAttendance(String userId) async {
    try {
      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day);
      final end = start.add(const Duration(days: 1));
      final q = await _firestore
          .collection('users')
          .doc(userId)
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end))
          .limit(1)
          .get();
      if (q.docs.isEmpty) return null;
      return AttendanceModel.fromFirestore(q.docs.first);
    } catch (e) {
      throw Exception('Failed to get today attendance: $e');
    }
  }

  Stream<AttendanceModel?> streamTodayAttendance(String userId) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('attendance')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty
            ? null
            : AttendanceModel.fromFirestore(s.docs.first));
  }

  Future<void> saveAttendance(
      String userId, AttendanceModel attendance) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('attendance')
          .doc(attendance.id)
          .set(attendance.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save attendance: $e');
    }
  }

  // ─── Check In ──────────────────────────────────────────────────────────────

  Future<AttendanceModel> checkIn(String userId,
      {WorkSchedule? schedule}) async {
    try {
      var attendance = await getTodayAttendance(userId);
      final now = DateTime.now();
      final goalMin = schedule?.requiredOdcMinutes ?? 480;
      final breakLimitMin = schedule?.allowedBreakMinutes ?? 60;

      if (attendance == null) {
        // Fresh day — create new record
        final dateKey =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        attendance = AttendanceModel(
          id: dateKey,
          userId: userId,
          date: DateTime(now.year, now.month, now.day),
          checkIn: now,
          isActive: true,
          sessions: [
            SessionModel(id: _uuid.v4(), startTime: now, type: 'odc'),
          ],
        );
      } else {
        // Already has a record (re-check-in after break / re-open)
        // Guard: don't add a new ODC session if the last one is already open ODC
        var sessions = List<SessionModel>.from(attendance.sessions);
        final lastIsOpenODC = sessions.isNotEmpty &&
            sessions.last.type == 'odc' &&
            sessions.last.endTime == null;
        if (!lastIsOpenODC) {
          // Close any hanging break session first
          sessions = _closeLastSession(sessions, now);
          sessions.add(
              SessionModel(id: _uuid.v4(), startTime: now, type: 'odc'));
        }
        attendance = attendance.copyWith(
          checkIn: attendance.checkIn ?? now,
          isActive: true,
          sessions: sessions,
        );
      }

      // Recalculate totals with correct schedule values
      attendance = _recalcTotals(
        attendance,
        goalMin: goalMin,
        breakLimitMin: breakLimitMin,
        checkOut: null,
        isActive: true,
      );
      await saveAttendance(userId, attendance);
      return attendance;
    } catch (e) {
      throw Exception('Failed to check in: $e');
    }
  }

  // ─── Check Out ─────────────────────────────────────────────────────────────

  /// [autoEndTime] is used when auto-closing at shift end instead of user tap.
  Future<AttendanceModel> checkOut(String userId,
      {WorkSchedule? schedule, DateTime? autoEndTime}) async {
    try {
      final attendance = await getTodayAttendance(userId);
      if (attendance == null) throw Exception('No active attendance found');

      final now = autoEndTime ?? DateTime.now();
      final goalMin = schedule?.requiredOdcMinutes ?? 480;
      final breakLimitMin = schedule?.allowedBreakMinutes ?? 60;

      // Close last open session (ODC or break) at [now]
      final sessions = _closeLastSession(
          List<SessionModel>.from(attendance.sessions), now);

      final updated = attendance.copyWith(sessions: sessions);
      final finalRecord = _recalcTotals(
        updated,
        goalMin: goalMin,
        breakLimitMin: breakLimitMin,
        checkOut: now,
        isActive: false,
      );

      await saveAttendance(userId, finalRecord);
      return finalRecord;
    } catch (e) {
      throw Exception('Failed to check out: $e');
    }
  }

  // ─── Auto end-of-shift ─────────────────────────────────────────────────────

  /// Called by the app lifecycle / timer when the clock reaches the schedule
  /// endTime. Only acts if there is an active, unclosed shift today.
  Future<void> autoEndShiftIfNeeded(
      String userId, WorkSchedule schedule) async {
    try {
      final attendance = await getTodayAttendance(userId);
      if (attendance == null || !attendance.isActive) return;

      final now = DateTime.now();
      // Build the exact endTime for today from the schedule string "HH:MM"
      final parts = schedule.endTime.split(':');
      final shiftEnd = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      // Only auto-close if we are past the shift end
      if (now.isBefore(shiftEnd)) return;

      await checkOut(userId,
          schedule: schedule, autoEndTime: shiftEnd);
    } catch (_) {
      // Non-critical — never crash the app
    }
  }

  // ─── Start Break ───────────────────────────────────────────────────────────

  Future<AttendanceModel> startBreak(String userId,
      {WorkSchedule? schedule}) async {
    try {
      final attendance = await getTodayAttendance(userId);
      if (attendance == null) throw Exception('Please check in first');

      var sessions = List<SessionModel>.from(attendance.sessions);
      // Guard: don't start another break if already on break
      if (sessions.isNotEmpty &&
          sessions.last.type == 'break' &&
          sessions.last.endTime == null) {
        throw Exception('Already on break');
      }

      final now = DateTime.now();
      // Close current ODC session
      sessions = _closeLastSession(sessions, now);
      // Open break session
      sessions.add(SessionModel(id: _uuid.v4(), startTime: now, type: 'break'));

      final updated = attendance.copyWith(sessions: sessions);
      final goalMin = schedule?.requiredOdcMinutes ?? 480;
      final breakLimitMin = schedule?.allowedBreakMinutes ?? 60;
      final finalRecord = _recalcTotals(
        updated,
        goalMin: goalMin,
        breakLimitMin: breakLimitMin,
        checkOut: null,
        isActive: true,
      );

      await saveAttendance(userId, finalRecord);
      return finalRecord;
    } catch (e) {
      throw Exception('Failed to start break: $e');
    }
  }

  // ─── End Break ─────────────────────────────────────────────────────────────

  Future<AttendanceModel> endBreak(String userId,
      {WorkSchedule? schedule}) async {
    try {
      final attendance = await getTodayAttendance(userId);
      if (attendance == null) throw Exception('No active attendance found');

      var sessions = List<SessionModel>.from(attendance.sessions);
      // Guard: only end break if actually on break
      if (sessions.isEmpty ||
          sessions.last.type != 'break' ||
          sessions.last.endTime != null) {
        throw Exception('Not currently on break');
      }

      final now = DateTime.now();
      // Close break session
      sessions = _closeLastSession(sessions, now);
      // Open new ODC session
      sessions.add(SessionModel(id: _uuid.v4(), startTime: now, type: 'odc'));

      final updated = attendance.copyWith(sessions: sessions);
      final goalMin = schedule?.requiredOdcMinutes ?? 480;
      final breakLimitMin = schedule?.allowedBreakMinutes ?? 60;
      final finalRecord = _recalcTotals(
        updated,
        goalMin: goalMin,
        breakLimitMin: breakLimitMin,
        checkOut: null,
        isActive: true,
      );

      await saveAttendance(userId, finalRecord);
      return finalRecord;
    } catch (e) {
      throw Exception('Failed to end break: $e');
    }
  }

  // ─── Attendance range ──────────────────────────────────────────────────────

  Future<List<AttendanceModel>> getAttendanceByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Use 'date' field with range query (requires composite index in Firestore)
      final q = await _firestore
          .collection('users')
          .doc(userId)
          .collection('attendance')
          .where('date',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(DateTime(startDate.year, startDate.month, startDate.day)))
          .where('date',
              isLessThanOrEqualTo:
                  Timestamp.fromDate(DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)))
          .orderBy('date', descending: true)
          .get();
      return q.docs.map(AttendanceModel.fromFirestore).toList();
    } catch (e) {
      // Fallback: fetch all and filter client-side (avoids missing-index error)
      try {
        final q = await _firestore
            .collection('users')
            .doc(userId)
            .collection('attendance')
            .orderBy('date', descending: true)
            .get();
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        final end = DateTime(
            endDate.year, endDate.month, endDate.day, 23, 59, 59);
        return q.docs
            .map(AttendanceModel.fromFirestore)
            .where((a) =>
                !a.date.isBefore(start) && !a.date.isAfter(end))
            .toList();
      } catch (e2) {
        throw Exception('Failed to get attendance: $e2');
      }
    }
  }

  // ─── Reminder history ──────────────────────────────────────────────────────

  Future<void> logReminderEvent({
    required String userId,
    required DateTime reminderTime,
    required int breakDurationMinutes,
    required String userStatus,
    bool notificationDelivered = true,
    bool notificationClicked = false,
    bool snoozed = false,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('reminder_history')
          .add({
        'reminderTime': Timestamp.fromDate(reminderTime),
        'breakDuration': breakDurationMinutes,
        'userStatus': userStatus,
        'notificationDelivered': notificationDelivered,
        'notificationClicked': notificationClicked,
        'snoozed': snoozed,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (_) {}
  }

  // ─── Notes ─────────────────────────────────────────────────────────────────

  Future<void> createNote(String userId, Note note) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(note.id)
          .set({
        'id': note.id,
        'title': note.title,
        'content': note.content,
        'createdAt': Timestamp.fromDate(note.createdAt),
        'updatedAt': Timestamp.fromDate(note.updatedAt),
        'isPinned': note.isPinned,
        'category': note.category,
        'tags': note.tags,
      });
    } catch (e) {
      throw Exception('Failed to create note: $e');
    }
  }

  Stream<List<Note>> streamNotes(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final notes = snapshot.docs.map((doc) {
        final data = doc.data();
        return Note(
          id: data['id'] ?? doc.id,
          title: data['title'] ?? '',
          content: data['content'] ?? '',
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
          isPinned: data['isPinned'] ?? false,
          category: data['category'] as String?,
          tags: List<String>.from(data['tags'] ?? []),
          checklist: [],
        );
      }).toList();
      notes.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      return notes;
    });
  }

  Future<void> updateNote(String userId, Note note) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(note.id)
          .update({
        'title': note.title,
        'content': note.content,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'isPinned': note.isPinned,
        'category': note.category,
        'tags': note.tags,
      });
    } catch (e) {
      throw Exception('Failed to update note: $e');
    }
  }

  Future<void> deleteNote(String userId, String noteId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(noteId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }

  // ─── Tasks ─────────────────────────────────────────────────────────────────

  Future<void> createTask(String userId, Task task) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(task.id)
          .set({
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'createdAt': Timestamp.fromDate(task.createdAt),
        'dueDate':
            task.dueDate != null ? Timestamp.fromDate(task.dueDate!) : null,
        'priority': task.priority.name,
        'isCompleted': task.isCompleted,
        'completedAt': task.completedAt != null
            ? Timestamp.fromDate(task.completedAt!)
            : null,
        'hasReminder': task.hasReminder,
        'reminderTime': task.reminderTime != null
            ? Timestamp.fromDate(task.reminderTime!)
            : null,
      });
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  Stream<List<Task>> streamTasks(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs.map((doc) {
        final data = doc.data();
        return Task(
          id: data['id'] ?? doc.id,
          title: data['title'] ?? '',
          description: data['description'] as String?,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          dueDate: data['dueDate'] != null
              ? (data['dueDate'] as Timestamp).toDate()
              : null,
          priority: TaskPriority.values.firstWhere(
            (p) => p.name == data['priority'],
            orElse: () => TaskPriority.medium,
          ),
          isCompleted: data['isCompleted'] ?? false,
          completedAt: data['completedAt'] != null
              ? (data['completedAt'] as Timestamp).toDate()
              : null,
          hasReminder: data['hasReminder'] ?? false,
          reminderTime: data['reminderTime'] != null
              ? (data['reminderTime'] as Timestamp).toDate()
              : null,
        );
      }).toList();
      tasks.sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
      return tasks;
    });
  }

  Future<void> updateTask(String userId, Task task) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(task.id)
          .update({
        'title': task.title,
        'description': task.description,
        'dueDate':
            task.dueDate != null ? Timestamp.fromDate(task.dueDate!) : null,
        'priority': task.priority.name,
        'isCompleted': task.isCompleted,
        'completedAt': task.completedAt != null
            ? Timestamp.fromDate(task.completedAt!)
            : null,
        'hasReminder': task.hasReminder,
        'reminderTime': task.reminderTime != null
            ? Timestamp.fromDate(task.reminderTime!)
            : null,
      });
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  Future<void> deleteTask(String userId, String taskId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  // ─── Work Schedules ────────────────────────────────────────────────────────

  Stream<List<WorkSchedule>> streamSchedules(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('workSchedules')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(WorkSchedule.fromFirestore).toList());
  }

  Future<List<WorkSchedule>> getSchedules(String userId) async {
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('workSchedules')
        .orderBy('createdAt', descending: false)
        .get();
    return snap.docs.map(WorkSchedule.fromFirestore).toList();
  }

  Future<WorkSchedule> getScheduleForDate(
      String userId, DateTime date) async {
    final schedules = await getSchedules(userId);
    if (schedules.isEmpty) {
      await seedDefaultSchedules(userId);
      return WorkSchedule.defaultScheduleA(userId);
    }
    final match = schedules.where((s) => s.isActiveOn(date)).toList();
    if (match.isNotEmpty) return match.last;
    final enabled = schedules.where((s) => s.enabled).toList();
    if (enabled.isNotEmpty) return enabled.first;
    return schedules.first;
  }

  Future<void> saveSchedule(String userId, WorkSchedule schedule) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('workSchedules')
        .doc(schedule.id)
        .set(schedule.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteSchedule(String userId, String scheduleId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('workSchedules')
        .doc(scheduleId)
        .delete();
  }

  Future<void> seedDefaultSchedules(String userId) async {
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('workSchedules')
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) return;
    await saveSchedule(userId, WorkSchedule.defaultScheduleA(userId));
    await saveSchedule(userId, WorkSchedule.defaultScheduleB(userId));
  }
}
