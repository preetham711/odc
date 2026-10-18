import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';

/// Enhanced Admin Service with full CRUD operations
/// SECURITY: All operations require admin role verification via Firestore rules
class AdminServiceEnhanced {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // USER MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all users with optional filters
  Stream<List<UserModel>> streamAllUsers({
    bool? isDisabled,
    String? role,
  }) {
    Query query = _db.collection('users').orderBy('createdAt', descending: true);
    
    if (isDisabled != null) {
      query = query.where('isDisabled', isEqualTo: isDisabled);
    }
    if (role != null) {
      query = query.where('role', isEqualTo: role);
    }
    
    return query.snapshots().map((s) => 
      s.docs.map(UserModel.fromFirestore).toList()
    );
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('users').doc(uid).update(data);
    
    // Log audit
    await _logAuditEvent(
      action: 'user_updated',
      targetUserId: uid,
      metadata: {'fields': data.keys.toList()},
    );
  }

  /// Disable/Enable user account
  Future<void> setUserDisabled(String uid, bool disabled) async {
    await _db.collection('users').doc(uid).update({
      'isDisabled': disabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    await _logAuditEvent(
      action: disabled ? 'user_disabled' : 'user_enabled',
      targetUserId: uid,
    );
  }

  /// Change user role
  Future<void> setUserRole(String uid, String role) async {
    await _db.collection('users').doc(uid).update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    await _logAuditEvent(
      action: 'role_changed',
      targetUserId: uid,
      metadata: {'newRole': role},
    );
  }

  /// COMPLETE USER DELETION
  /// Deletes user from Firestore AND marks for auth deletion
  /// Note: Firebase Auth deletion requires backend/Cloud Function in production
  Future<DeleteUserResult> deleteUser(String uid) async {
    try {
      final adminUid = _auth.currentUser?.uid;
      if (adminUid == null) {
        return DeleteUserResult(
          success: false,
          message: 'Admin not authenticated',
        );
      }

      // 1. Get user data before deletion for audit
      final user = await getUserById(uid);
      if (user == null) {
        return DeleteUserResult(
          success: false,
          message: 'User not found',
        );
      }

      // 2. Delete all user subcollections
      await _deleteUserSubcollections(uid);

      // 3. Delete user document
      await _db.collection('users').doc(uid).delete();

      // 4. Create deletion marker (for reference and audit)
      await _db.collection('deleted_users').doc(uid).set({
        'uid': uid,
        'fullName': user.fullName,
        'email': user.email,
        'mobileNumber': user.mobileNumber,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': adminUid,
        'reason': 'admin_deletion',
      });

      // 5. Log comprehensive audit
      await _logAuditEvent(
        action: 'user_deleted',
        targetUserId: uid,
        metadata: {
          'userName': user.fullName,
          'userEmail': user.email,
          'userPhone': user.mobileNumber,
        },
      );

      // 6. Attempt to delete from Firebase Auth (if current user)
      // Note: This only works if deleting your own account
      // For other users, this requires Cloud Function
      bool authDeleted = false;
      try {
        if (_auth.currentUser?.uid == uid) {
          await _auth.currentUser?.delete();
          authDeleted = true;
        }
      } catch (e) {
        debugPrint('Auth deletion requires backend: $e');
      }

      return DeleteUserResult(
        success: true,
        message: authDeleted 
          ? 'User deleted completely'
          : 'User data deleted. Auth account requires backend deletion.',
        authDeleted: authDeleted,
      );

    } catch (e) {
      debugPrint('Error deleting user: $e');
      return DeleteUserResult(
        success: false,
        message: 'Deletion failed: $e',
      );
    }
  }

  /// Delete all user subcollections
  Future<void> _deleteUserSubcollections(String uid) async {
    final subcollections = [
      'attendance',
      'notes',
      'tasks',
      'workSchedules',
      'reminder_history',
      'sessions',
      'notifications',
    ];

    for (final subcollection in subcollections) {
      await _deleteCollection(
        _db.collection('users').doc(uid).collection(subcollection),
      );
    }
  }

  /// Delete entire collection (batch delete)
  Future<void> _deleteCollection(CollectionReference collection) async {
    const batchSize = 100;
    
    while (true) {
      final snapshot = await collection.limit(batchSize).get();
      if (snapshot.docs.isEmpty) break;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ATTENDANCE & ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get user attendance for date range
  Future<List<AttendanceModel>> getUserAttendance(
    String uid, {
    DateTime? from,
    DateTime? to,
  }) async {
    Query query = _db
        .collection('users')
        .doc(uid)
        .collection('attendance')
        .orderBy('date', descending: true);

    if (from != null) {
      query = query.where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime(from.year, from.month, from.day)));
    }
    if (to != null) {
      query = query.where('date',
          isLessThanOrEqualTo: Timestamp.fromDate(
              DateTime(to.year, to.month, to.day, 23, 59, 59)));
    }

    final snap = await query.get();
    return snap.docs.map(AttendanceModel.fromFirestore).toList();
  }

  /// Get admin dashboard statistics
  Future<AdminStats> getAdminStats() async {
    final users = await _db.collection('users').get();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    int totalUsers = 0;
    int activeUsers = 0;
    int disabledUsers = 0;
    int adminUsers = 0;
    int checkedInToday = 0;
    int onBreakNow = 0;
    int totalODCMinutesToday = 0;

    for (final doc in users.docs) {
      final user = UserModel.fromFirestore(doc);
      totalUsers++;
      
      if (user.isDisabled) {
        disabledUsers++;
      } else {
        activeUsers++;
      }
      
      if (user.isAdmin) {
        adminUsers++;
      }

      // Get today's attendance
      try {
        final attSnap = await _db
            .collection('users')
            .doc(user.uid)
            .collection('attendance')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
            .limit(1)
            .get();

        if (attSnap.docs.isNotEmpty) {
          final att = AttendanceModel.fromFirestore(attSnap.docs.first);
          if (att.isActive) checkedInToday++;
          if (att.sessions.isNotEmpty &&
              att.sessions.last.type == 'break' &&
              att.sessions.last.endTime == null) {
            onBreakNow++;
          }
          totalODCMinutesToday += att.odcTime;
        }
      } catch (e) {
        debugPrint('Error getting attendance for ${user.uid}: $e');
      }
    }

    return AdminStats(
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      disabledUsers: disabledUsers,
      adminUsers: adminUsers,
      checkedInToday: checkedInToday,
      onBreakNow: onBreakNow,
      totalODCMinutesToday: totalODCMinutesToday,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUDIT LOGGING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Log admin action for audit trail
  Future<void> _logAuditEvent({
    required String action,
    String? targetUserId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final adminUid = _auth.currentUser?.uid;
      if (adminUid == null) return;

      await _db.collection('admin_audit_logs').add({
        'adminUid': adminUid,
        'action': action,
        'targetUserId': targetUserId,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.toString(),
      });
    } catch (e) {
      debugPrint('Error logging audit: $e');
    }
  }

  /// Get audit logs with optional filters
  Stream<List<AuditLog>> streamAuditLogs({
    String? adminUid,
    String? targetUserId,
    String? action,
    int limit = 100,
  }) {
    Query query = _db
        .collection('admin_audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (adminUid != null) {
      query = query.where('adminUid', isEqualTo: adminUid);
    }
    if (targetUserId != null) {
      query = query.where('targetUserId', isEqualTo: targetUserId);
    }
    if (action != null) {
      query = query.where('action', isEqualTo: action);
    }

    return query.snapshots().map((s) =>
        s.docs.map((d) => AuditLog.fromFirestore(d)).toList());
  }

  /// Get audit logs for specific user
  Future<List<AuditLog>> getUserAuditLogs(String uid, {int limit = 50}) async {
    final snap = await _db
        .collection('admin_audit_logs')
        .where('targetUserId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snap.docs.map((d) => AuditLog.fromFirestore(d)).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH & FILTERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Search users by name, email, or phone
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    final queryLower = query.toLowerCase();
    final allUsers = await _db.collection('users').get();

    return allUsers.docs
        .map(UserModel.fromFirestore)
        .where((user) =>
            user.fullName.toLowerCase().contains(queryLower) ||
            (user.email?.toLowerCase().contains(queryLower) ?? false) ||
            user.mobileNumber.contains(query))
        .toList();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════════════════

class AdminStats {
  final int totalUsers;
  final int activeUsers;
  final int disabledUsers;
  final int adminUsers;
  final int checkedInToday;
  final int onBreakNow;
  final int totalODCMinutesToday;

  const AdminStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.disabledUsers,
    required this.adminUsers,
    required this.checkedInToday,
    required this.onBreakNow,
    required this.totalODCMinutesToday,
  });
}

class DeleteUserResult {
  final bool success;
  final String message;
  final bool authDeleted;

  const DeleteUserResult({
    required this.success,
    required this.message,
    this.authDeleted = false,
  });
}

class AuditLog {
  final String id;
  final String adminUid;
  final String action;
  final String? targetUserId;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final String platform;

  const AuditLog({
    required this.id,
    required this.adminUid,
    required this.action,
    this.targetUserId,
    required this.metadata,
    required this.timestamp,
    required this.platform,
  });

  factory AuditLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLog(
      id: doc.id,
      adminUid: data['adminUid'] ?? '',
      action: data['action'] ?? '',
      targetUserId: data['targetUserId'],
      metadata: data['metadata'] ?? {},
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      platform: data['platform'] ?? '',
    );
  }
}
