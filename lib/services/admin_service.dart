import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';

/// All admin-only Firestore operations.
/// Security: these calls only succeed because Firestore security rules
/// allow reads on other users' data only when the caller's role == 'admin'.
class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Users ─────────────────────────────────────────────────────────────────

  /// Stream of ALL registered users, ordered by creation date (newest first).
  Stream<List<UserModel>> streamAllUsers() {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(UserModel.fromFirestore).toList());
  }

  Future<List<UserModel>> getAllUsers() async {
    final snap = await _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(UserModel.fromFirestore).toList();
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _db.collection('users').doc(uid).update(data);
  }

  /// Disable or enable a user account (sets isDisabled flag).
  Future<void> setUserDisabled(String uid, bool disabled) async {
    await _db.collection('users').doc(uid).update({
      'isDisabled': disabled,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Promote or demote a user.
  Future<void> setUserRole(String uid, String role) async {
    await _db.collection('users').doc(uid).update({
      'role': role,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Hard-delete a user document (does NOT delete Firebase Auth — that
  /// requires Admin SDK on a backend).
  Future<void> deleteUserData(String uid) async {
    // Delete all subcollections
    for (final sub in ['attendance', 'notes', 'tasks', 'workSchedules',
        'reminder_history']) {
      final batch = _db.batch();
      final docs = await _db
          .collection('users')
          .doc(uid)
          .collection(sub)
          .limit(100)
          .get();
      for (final d in docs.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
    await _db.collection('users').doc(uid).delete();
  }

  // ─── Attendance ────────────────────────────────────────────────────────────

  /// Get all attendance records for a specific user.
  Future<List<AttendanceModel>> getUserAttendance(
    String uid, {
    DateTime? from,
    DateTime? to,
  }) async {
    Query q = _db
        .collection('users')
        .doc(uid)
        .collection('attendance')
        .orderBy('date', descending: true);

    if (from != null) {
      q = q.where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime(from.year, from.month, from.day)));
    }
    if (to != null) {
      q = q.where('date',
          isLessThanOrEqualTo: Timestamp.fromDate(
              DateTime(to.year, to.month, to.day, 23, 59, 59)));
    }

    final snap = await q.limit(90).get();
    return snap.docs.map(AttendanceModel.fromFirestore).toList();
  }

  /// Stream today's attendance for a user.
  Stream<AttendanceModel?> streamUserTodayAttendance(String uid) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    return _db
        .collection('users')
        .doc(uid)
        .collection('attendance')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty
            ? null
            : AttendanceModel.fromFirestore(s.docs.first));
  }

  // ─── Statistics ────────────────────────────────────────────────────────────

  /// Overall statistics across all users (for admin dashboard).
  Future<AdminStats> getAdminStats() async {
    final users = await getAllUsers();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final monthStart = DateTime(now.year, now.month, 1);

    int checkedInToday = 0;
    int onBreakNow = 0;
    int totalODCMinutesToday = 0;
    int totalPerfectDaysThisMonth = 0;

    // Check today's status for all users
    final futures = users.map((u) async {
      try {
        final snap = await _db
            .collection('users')
            .doc(u.uid)
            .collection('attendance')
            .where('date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
            .where('date', isLessThan: Timestamp.fromDate(todayEnd))
            .limit(1)
            .get();

        if (snap.docs.isEmpty) return;
        final att = AttendanceModel.fromFirestore(snap.docs.first);
        if (att.isActive) checkedInToday++;
        if (att.sessions.isNotEmpty &&
            att.sessions.last.type == 'break' &&
            att.sessions.last.endTime == null) {
          onBreakNow++;
        }
        totalODCMinutesToday += att.odcTime;
      } catch (_) {}
    });

    await Future.wait(futures);

    // Monthly perfect days across all users
    final monthlyFutures = users.map((u) async {
      try {
        final snap = await _db
            .collection('users')
            .doc(u.uid)
            .collection('attendance')
            .where('date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(now))
            .get();
        for (final d in snap.docs) {
          final att = AttendanceModel.fromFirestore(d);
          if (att.completionPercentage >= 100) totalPerfectDaysThisMonth++;
        }
      } catch (_) {}
    });

    await Future.wait(monthlyFutures);

    return AdminStats(
      totalUsers: users.length,
      checkedInToday: checkedInToday,
      onBreakNow: onBreakNow,
      totalODCMinutesToday: totalODCMinutesToday,
      totalPerfectDaysThisMonth: totalPerfectDaysThisMonth,
      activeUsers: users.where((u) => !u.isDisabled).length,
      adminCount: users.where((u) => u.isAdmin).length,
    );
  }

  /// Per-user stats summary for a date range.
  Future<UserStats> getUserStats(
    String uid, {
    required DateTime from,
    required DateTime to,
  }) async {
    final attendance = await getUserAttendance(uid, from: from, to: to);
    if (attendance.isEmpty) {
      return UserStats(
          uid: uid,
          totalDays: 0,
          totalODCMinutes: 0,
          totalBreakMinutes: 0,
          perfectDays: 0,
          missedDays: 0,
          avgODCMinutes: 0,
          attendance: []);
    }

    int totalODC = 0, totalBreak = 0, perfectDays = 0, missedDays = 0;
    for (final a in attendance) {
      totalODC += a.odcTime;
      totalBreak += a.breakTime;
      if (a.completionPercentage >= 100) perfectDays++;
      if (a.odcTime == 0) missedDays++;
    }

    return UserStats(
      uid: uid,
      totalDays: attendance.length,
      totalODCMinutes: totalODC,
      totalBreakMinutes: totalBreak,
      perfectDays: perfectDays,
      missedDays: missedDays,
      avgODCMinutes: totalODC ~/ attendance.length,
      attendance: attendance,
    );
  }
}

// ─── Data classes ──────────────────────────────────────────────────────────────

class AdminStats {
  final int totalUsers;
  final int checkedInToday;
  final int onBreakNow;
  final int totalODCMinutesToday;
  final int totalPerfectDaysThisMonth;
  final int activeUsers;
  final int adminCount;

  const AdminStats({
    required this.totalUsers,
    required this.checkedInToday,
    required this.onBreakNow,
    required this.totalODCMinutesToday,
    required this.totalPerfectDaysThisMonth,
    required this.activeUsers,
    required this.adminCount,
  });
}

class UserStats {
  final String uid;
  final int totalDays;
  final int totalODCMinutes;
  final int totalBreakMinutes;
  final int perfectDays;
  final int missedDays;
  final int avgODCMinutes;
  final List<AttendanceModel> attendance;

  const UserStats({
    required this.uid,
    required this.totalDays,
    required this.totalODCMinutes,
    required this.totalBreakMinutes,
    required this.perfectDays,
    required this.missedDays,
    required this.avgODCMinutes,
    required this.attendance,
  });
}
