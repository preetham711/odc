import 'package:cloud_firestore/cloud_firestore.dart';

/// Leave request model with approval workflow
class LeaveModel {
  final String id;
  final String userId;
  final String userName; // For display in admin panel
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final String reason;
  final LeaveStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy; // Admin UID who approved/rejected
  final String? reviewerName;
  final String? rejectionReason;
  final List<String>? attachments; // URLs to supporting documents

  const LeaveModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewerName,
    this.rejectionReason,
    this.attachments,
  });

  bool get isPending => status == LeaveStatus.pending;
  bool get isApproved => status == LeaveStatus.approved;
  bool get isRejected => status == LeaveStatus.rejected;
  bool get isCancelled => status == LeaveStatus.cancelled;

  factory LeaveModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaveModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      type: LeaveType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => LeaveType.casual,
      ),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      totalDays: data['totalDays'] ?? 0,
      reason: data['reason'] ?? '',
      status: LeaveStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => LeaveStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewedBy: data['reviewedBy'] as String?,
      reviewerName: data['reviewerName'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
      attachments: (data['attachments'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'type': type.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalDays': totalDays,
      'reason': reason,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt':
          reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'reviewerName': reviewerName,
      'rejectionReason': rejectionReason,
      'attachments': attachments,
    };
  }

  LeaveModel copyWith({
    LeaveStatus? status,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewerName,
    String? rejectionReason,
  }) {
    return LeaveModel(
      id: id,
      userId: userId,
      userName: userName,
      type: type,
      startDate: startDate,
      endDate: endDate,
      totalDays: totalDays,
      reason: reason,
      status: status ?? this.status,
      createdAt: createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewerName: reviewerName ?? this.reviewerName,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      attachments: attachments,
    );
  }
}

/// Leave types with quota tracking
enum LeaveType {
  casual('Casual Leave', 12),
  sick('Sick Leave', 10),
  annual('Annual Leave', 15),
  unpaid('Unpaid Leave', 0),
  emergency('Emergency Leave', 3),
  maternity('Maternity Leave', 90),
  paternity('Paternity Leave', 15);

  final String displayName;
  final int yearlyQuota; // 0 means unlimited/not counted

  const LeaveType(this.displayName, this.yearlyQuota);
}

/// Leave request status
enum LeaveStatus {
  pending('Pending', 0xFFFFA726), // Orange
  approved('Approved', 0xFF66BB6A), // Green
  rejected('Rejected', 0xFFEF5350), // Red
  cancelled('Cancelled', 0xFF9E9E9E); // Grey

  final String displayName;
  final int color;

  const LeaveStatus(this.displayName, this.color);
}

/// Leave balance tracking per user
class LeaveBalance {
  final String userId;
  final int year;
  final Map<LeaveType, int> available; // Days remaining
  final Map<LeaveType, int> used; // Days consumed
  final Map<LeaveType, int> pending; // Days in pending requests
  final DateTime updatedAt;

  const LeaveBalance({
    required this.userId,
    required this.year,
    required this.available,
    required this.used,
    required this.pending,
    required this.updatedAt,
  });

  /// Calculate total available for a specific leave type
  int getAvailable(LeaveType type) => available[type] ?? 0;

  /// Calculate total used for a specific leave type
  int getUsed(LeaveType type) => used[type] ?? 0;

  /// Calculate pending for a specific leave type
  int getPending(LeaveType type) => pending[type] ?? 0;

  /// Check if user can apply for [days] of [type]
  bool canApply(LeaveType type, int days) {
    if (type.yearlyQuota == 0) return true; // Unlimited
    final availableDays = getAvailable(type);
    return availableDays >= days;
  }

  factory LeaveBalance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaveBalance(
      userId: data['userId'] ?? '',
      year: data['year'] ?? DateTime.now().year,
      available: (data['available'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              LeaveType.values.firstWhere((e) => e.name == k),
              v as int,
            ),
          ) ??
          {},
      used: (data['used'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              LeaveType.values.firstWhere((e) => e.name == k),
              v as int,
            ),
          ) ??
          {},
      pending: (data['pending'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              LeaveType.values.firstWhere((e) => e.name == k),
              v as int,
            ),
          ) ??
          {},
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'year': year,
      'available': available.map((k, v) => MapEntry(k.name, v)),
      'used': used.map((k, v) => MapEntry(k.name, v)),
      'pending': pending.map((k, v) => MapEntry(k.name, v)),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Initialize default balance for a new year
  factory LeaveBalance.defaultForYear(String userId, int year) {
    final available = <LeaveType, int>{};
    final used = <LeaveType, int>{};
    final pending = <LeaveType, int>{};

    for (final type in LeaveType.values) {
      available[type] = type.yearlyQuota;
      used[type] = 0;
      pending[type] = 0;
    }

    return LeaveBalance(
      userId: userId,
      year: year,
      available: available,
      used: used,
      pending: pending,
      updatedAt: DateTime.now(),
    );
  }

  LeaveBalance copyWith({
    Map<LeaveType, int>? available,
    Map<LeaveType, int>? used,
    Map<LeaveType, int>? pending,
    DateTime? updatedAt,
  }) {
    return LeaveBalance(
      userId: userId,
      year: year,
      available: available ?? this.available,
      used: used ?? this.used,
      pending: pending ?? this.pending,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
