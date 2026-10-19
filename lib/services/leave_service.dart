import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/leave_model.dart';
import '../models/user_model.dart';

/// Complete leave management service
/// Handles leave requests, approvals, balance tracking
class LeaveService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // LEAVE APPLICATION (User-facing)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Apply for leave
  Future<LeaveModel> applyLeave({
    required String userId,
    required String userName,
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    List<String>? attachments,
  }) async {
    try {
      // Calculate total days (inclusive)
      final totalDays = endDate.difference(startDate).inDays + 1;

      // Check leave balance
      final balance = await getLeaveBalance(userId);
      if (!balance.canApply(type, totalDays)) {
        throw Exception(
            'Insufficient ${type.displayName} balance. Available: ${balance.getAvailable(type)} days');
      }

      // Check for overlapping leave requests
      final overlapping = await _checkOverlappingLeaves(userId, startDate, endDate);
      if (overlapping) {
        throw Exception('You have overlapping leave requests for these dates');
      }

      // Create leave request
      final leave = LeaveModel(
        id: '', // Firestore will assign
        userId: userId,
        userName: userName,
        type: type,
        startDate: DateTime(startDate.year, startDate.month, startDate.day),
        endDate: DateTime(endDate.year, endDate.month, endDate.day),
        totalDays: totalDays,
        reason: reason,
        status: LeaveStatus.pending,
        createdAt: DateTime.now(),
        attachments: attachments,
      );

      // Save to Firestore
      final docRef = await _db
          .collection('users')
          .doc(userId)
          .collection('leaves')
          .add(leave.toFirestore());

      // Update balance - add to pending
      await _updateBalanceOnApplication(userId, type, totalDays);

      // Create notification for admins
      await _notifyAdminsOfLeaveRequest(leave.copyWith());

      return leave.copyWith();
    } catch (e) {
      debugPrint('Error applying leave: $e');
      rethrow;
    }
  }

  /// Cancel leave request (only if pending)
  Future<void> cancelLeave(String userId, String leaveId) async {
    try {
      final leaveDoc = await _db
          .collection('users')
          .doc(userId)
          .collection('leaves')
          .doc(leaveId)
          .get();

      if (!leaveDoc.exists) throw Exception('Leave request not found');

      final leave = LeaveModel.fromFirestore(leaveDoc);

      if (!leave.isPending) {
        throw Exception('Only pending leave requests can be cancelled');
      }

      // Update status to cancelled
      await _db
          .collection('users')
          .doc(userId)
          .collection('leaves')
          .doc(leaveId)
          .update({
        'status': LeaveStatus.cancelled.name,
      });

      // Restore balance from pending
      await _restoreBalanceFromPending(userId, leave.type, leave.totalDays);
    } catch (e) {
      debugPrint('Error cancelling leave: $e');
      rethrow;
    }
  }

  /// Get user's leave requests
  Stream<List<LeaveModel>> streamUserLeaves(
    String userId, {
    LeaveStatus? status,
    int? year,
  }) {
    Query query = _db
        .collection('users')
        .doc(userId)
        .collection('leaves')
        .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    if (year != null) {
      final startOfYear = DateTime(year, 1, 1);
      final endOfYear = DateTime(year, 12, 31, 23, 59, 59);
      query = query
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfYear));
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs.map(LeaveModel.fromFirestore).toList(),
        );
  }

  /// Get leave by ID
  Future<LeaveModel?> getLeaveById(String userId, String leaveId) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(userId)
          .collection('leaves')
          .doc(leaveId)
          .get();

      if (!doc.exists) return null;
      return LeaveModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting leave: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN - LEAVE APPROVAL/REJECTION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all pending leave requests (admin only)
  Stream<List<LeaveModel>> streamAllPendingLeaves() {
    return _db
        .collectionGroup('leaves')
        .where('status', isEqualTo: LeaveStatus.pending.name)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(LeaveModel.fromFirestore).toList(),
        );
  }

  /// Get all leaves with filters (admin only)
  Stream<List<LeaveModel>> streamAllLeaves({
    LeaveStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    Query query = _db.collectionGroup('leaves').orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    if (fromDate != null) {
      query = query.where('startDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate));
    }

    if (toDate != null) {
      query = query.where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(toDate));
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs.map(LeaveModel.fromFirestore).toList(),
        );
  }

  /// Approve leave request (admin only)
  Future<void> approveLeave({
    required String userId,
    required String leaveId,
    required String adminId,
    required String adminName,
  }) async {
    try {
      final leaveDoc = await _db
          .collection('users')
          .doc(userId)
          .collection('leaves')
          .doc(leaveId)
          .get();

      if (!leaveDoc.exists) throw Exception('Leave request not found');

      final leave = LeaveModel.fromFirestore(leaveDoc);

      if (!leave.isPending) {
        throw Exception('Leave request is not in pending status');
      }

      // Update leave status
      await _db
          .collection('users')
          .doc(userId)
          .collection('leaves')
          .doc(leaveId)
          .update({
        'status': LeaveStatus.approved.name,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminId,
        'reviewerName': adminName,
      });

      // Update balance: move from pending to used
      await _approveBalanceUpdate(userId, leave.type, leave.totalDays);

      // Create notification for user
      await _notifyUserOfLeaveApproval(userId, leave);

      // Log audit
      await _logLeaveAction(
        action: 'leave_approved',
        userId: userId,
        leaveId: leaveId,
        adminId: adminId,
        metadata: {
          'type': leave.type.name,
          'days': leave.totalDays,
          'startDate': leave.startDate.toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error approving leave: $e');
      rethrow;
    }
  }

  /// Reject leave request (admin only)
  Future<void> rejectLeave({
    required String userId,
    required String leaveId,
    required String adminId,
    required String adminName,
    required String reason,
  }) async {
    try {
      final leaveDoc = await _db
          .collection('users')
          .doc(userId)
          .collection('leaves')
          .doc(leaveId)
          .get();

      if (!leaveDoc.exists) throw Exception('Leave request not found');

      final leave = LeaveModel.fromFirestore(leaveDoc);

      if (!leave.isPending) {
        throw Exception('Leave request is not in pending status');
      }

      // Update leave status
      await _db
          .collection('users')
          .doc(userId)
          .collection('leaves')
          .doc(leaveId)
          .update({
        'status': LeaveStatus.rejected.name,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminId,
        'reviewerName': adminName,
        'rejectionReason': reason,
      });

      // Restore balance from pending
      await _restoreBalanceFromPending(userId, leave.type, leave.totalDays);

      // Create notification for user
      await _notifyUserOfLeaveRejection(userId, leave, reason);

      // Log audit
      await _logLeaveAction(
        action: 'leave_rejected',
        userId: userId,
        leaveId: leaveId,
        adminId: adminId,
        metadata: {
          'type': leave.type.name,
          'days': leave.totalDays,
          'reason': reason,
        },
      );
    } catch (e) {
      debugPrint('Error rejecting leave: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEAVE BALANCE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get leave balance for user (current year)
  Future<LeaveBalance> getLeaveBalance(String userId) async {
    try {
      final currentYear = DateTime.now().year;
      final docId = '${userId}_$currentYear';

      final doc = await _db.collection('leave_balances').doc(docId).get();

      if (!doc.exists) {
        // Initialize default balance for the year
        final balance = LeaveBalance.defaultForYear(userId, currentYear);
        await _db.collection('leave_balances').doc(docId).set(balance.toFirestore());
        return balance;
      }

      return LeaveBalance.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting leave balance: $e');
      return LeaveBalance.defaultForYear(userId, DateTime.now().year);
    }
  }

  /// Stream leave balance
  Stream<LeaveBalance> streamLeaveBalance(String userId) {
    final currentYear = DateTime.now().year;
    final docId = '${userId}_$currentYear';

    return _db.collection('leave_balances').doc(docId).snapshots().map((doc) {
      if (!doc.exists) {
        return LeaveBalance.defaultForYear(userId, currentYear);
      }
      return LeaveBalance.fromFirestore(doc);
    });
  }

  /// Admin: Manually adjust leave balance
  Future<void> adjustLeaveBalance({
    required String userId,
    required LeaveType type,
    required int daysToAdd,
    required String reason,
    required String adminId,
  }) async {
    try {
      final balance = await getLeaveBalance(userId);
      final currentAvailable = balance.getAvailable(type);
      final newAvailable = (currentAvailable + daysToAdd).clamp(0, 365);

      final updatedAvailable = Map<LeaveType, int>.from(balance.available);
      updatedAvailable[type] = newAvailable;

      final currentYear = DateTime.now().year;
      final docId = '${userId}_$currentYear';

      await _db.collection('leave_balances').doc(docId).update({
        'available': updatedAvailable.map((k, v) => MapEntry(k.name, v)),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log audit
      await _logLeaveAction(
        action: 'balance_adjusted',
        userId: userId,
        leaveId: null,
        adminId: adminId,
        metadata: {
          'type': type.name,
          'adjustment': daysToAdd,
          'newBalance': newAvailable,
          'reason': reason,
        },
      );
    } catch (e) {
      debugPrint('Error adjusting leave balance: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if there are overlapping leave requests
  Future<bool> _checkOverlappingLeaves(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final leaves = await _db
        .collection('users')
        .doc(userId)
        .collection('leaves')
        .where('status', whereIn: [
          LeaveStatus.pending.name,
          LeaveStatus.approved.name
        ])
        .get();

    for (final doc in leaves.docs) {
      final leave = LeaveModel.fromFirestore(doc);
      // Check for date overlap
      if (!(endDate.isBefore(leave.startDate) || startDate.isAfter(leave.endDate))) {
        return true; // Overlap found
      }
    }

    return false;
  }

  /// Update balance when leave is applied (move to pending)
  Future<void> _updateBalanceOnApplication(
    String userId,
    LeaveType type,
    int days,
  ) async {
    final balance = await getLeaveBalance(userId);
    final updatedPending = Map<LeaveType, int>.from(balance.pending);
    updatedPending[type] = balance.getPending(type) + days;

    final currentYear = DateTime.now().year;
    final docId = '${userId}_$currentYear';

    await _db.collection('leave_balances').doc(docId).update({
      'pending': updatedPending.map((k, v) => MapEntry(k.name, v)),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Approve: move from pending to used, deduct from available
  Future<void> _approveBalanceUpdate(
    String userId,
    LeaveType type,
    int days,
  ) async {
    final balance = await getLeaveBalance(userId);

    final updatedAvailable = Map<LeaveType, int>.from(balance.available);
    final updatedUsed = Map<LeaveType, int>.from(balance.used);
    final updatedPending = Map<LeaveType, int>.from(balance.pending);

    updatedAvailable[type] = (balance.getAvailable(type) - days).clamp(0, 365);
    updatedUsed[type] = balance.getUsed(type) + days;
    updatedPending[type] = (balance.getPending(type) - days).clamp(0, 365);

    final currentYear = DateTime.now().year;
    final docId = '${userId}_$currentYear';

    await _db.collection('leave_balances').doc(docId).update({
      'available': updatedAvailable.map((k, v) => MapEntry(k.name, v)),
      'used': updatedUsed.map((k, v) => MapEntry(k.name, v)),
      'pending': updatedPending.map((k, v) => MapEntry(k.name, v)),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Restore balance when leave is cancelled or rejected
  Future<void> _restoreBalanceFromPending(
    String userId,
    LeaveType type,
    int days,
  ) async {
    final balance = await getLeaveBalance(userId);
    final updatedPending = Map<LeaveType, int>.from(balance.pending);
    updatedPending[type] = (balance.getPending(type) - days).clamp(0, 365);

    final currentYear = DateTime.now().year;
    final docId = '${userId}_$currentYear';

    await _db.collection('leave_balances').doc(docId).update({
      'pending': updatedPending.map((k, v) => MapEntry(k.name, v)),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Notify admins of new leave request
  Future<void> _notifyAdminsOfLeaveRequest(LeaveModel leave) async {
    try {
      // Get all admin users
      final admins = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      for (final adminDoc in admins.docs) {
        await _db
            .collection('users')
            .doc(adminDoc.id)
            .collection('notifications')
            .add({
          'title': 'New Leave Request',
          'body':
              '${leave.userName} requested ${leave.totalDays} day(s) of ${leave.type.displayName}',
          'type': 'leave_request',
          'leaveId': leave.id,
          'userId': leave.userId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error notifying admins: $e');
    }
  }

  /// Notify user of leave approval
  Future<void> _notifyUserOfLeaveApproval(String userId, LeaveModel leave) async {
    try {
      await _db.collection('users').doc(userId).collection('notifications').add({
        'title': 'Leave Approved',
        'body':
            'Your ${leave.type.displayName} request for ${leave.totalDays} day(s) has been approved',
        'type': 'leave_approved',
        'leaveId': leave.id,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error notifying user: $e');
    }
  }

  /// Notify user of leave rejection
  Future<void> _notifyUserOfLeaveRejection(
    String userId,
    LeaveModel leave,
    String reason,
  ) async {
    try {
      await _db.collection('users').doc(userId).collection('notifications').add({
        'title': 'Leave Rejected',
        'body':
            'Your ${leave.type.displayName} request has been rejected. Reason: $reason',
        'type': 'leave_rejected',
        'leaveId': leave.id,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error notifying user: $e');
    }
  }

  /// Log leave-related actions for audit
  Future<void> _logLeaveAction({
    required String action,
    required String userId,
    String? leaveId,
    String? adminId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _db.collection('admin_audit_logs').add({
        'action': action,
        'targetUserId': userId,
        'adminUid': adminId,
        'leaveId': leaveId,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error logging leave action: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATISTICS & ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get leave statistics for a user
  Future<LeaveStatistics> getUserLeaveStats(String userId, int year) async {
    try {
      final startOfYear = DateTime(year, 1, 1);
      final endOfYear = DateTime(year, 12, 31);

      final leaves = await _db
          .collection('users')
          .doc(userId)
          .collection('leaves')
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfYear))
          .get();

      int totalApplied = 0;
      int totalApproved = 0;
      int totalRejected = 0;
      int totalPending = 0;
      int totalDaysTaken = 0;

      for (final doc in leaves.docs) {
        final leave = LeaveModel.fromFirestore(doc);
        totalApplied++;

        if (leave.isApproved) {
          totalApproved++;
          totalDaysTaken += leave.totalDays;
        } else if (leave.isRejected) {
          totalRejected++;
        } else if (leave.isPending) {
          totalPending++;
        }
      }

      final balance = await getLeaveBalance(userId);

      return LeaveStatistics(
        userId: userId,
        year: year,
        totalApplied: totalApplied,
        totalApproved: totalApproved,
        totalRejected: totalRejected,
        totalPending: totalPending,
        totalDaysTaken: totalDaysTaken,
        balance: balance,
      );
    } catch (e) {
      debugPrint('Error getting leave stats: $e');
      rethrow;
    }
  }
}

/// Leave statistics model
class LeaveStatistics {
  final String userId;
  final int year;
  final int totalApplied;
  final int totalApproved;
  final int totalRejected;
  final int totalPending;
  final int totalDaysTaken;
  final LeaveBalance balance;

  const LeaveStatistics({
    required this.userId,
    required this.year,
    required this.totalApplied,
    required this.totalApproved,
    required this.totalRejected,
    required this.totalPending,
    required this.totalDaysTaken,
    required this.balance,
  });

  double get approvalRate =>
      totalApplied > 0 ? (totalApproved / totalApplied * 100) : 0.0;
}
