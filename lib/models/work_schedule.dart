import 'package:cloud_firestore/cloud_firestore.dart';

/// A work schedule defines a shift window, ODC requirement and break allowance.
/// Multiple schedules can exist and are date-range aware:
/// the schedule whose [effectiveFrom] ≤ date < [effectiveUntil] is active.
class WorkSchedule {
  final String id;
  final String userId;
  final String name;

  /// 24-hour strings like "13:00"
  final String startTime;
  final String endTime;

  final int requiredOdcMinutes;
  final int allowedBreakMinutes;

  /// inclusive start date — null means "from the beginning of time"
  final DateTime? effectiveFrom;

  /// exclusive end date — null means "open ended / current"
  final DateTime? effectiveUntil;

  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkSchedule({
    required this.id,
    required this.userId,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.requiredOdcMinutes = 480,
    this.allowedBreakMinutes = 60,
    this.effectiveFrom,
    this.effectiveUntil,
    this.enabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Derived helpers ────────────────────────────────────────────────────────

  /// True when this schedule is active on [date].
  bool isActiveOn(DateTime date) {
    if (!enabled) return false;
    final d = DateTime(date.year, date.month, date.day);
    if (effectiveFrom != null) {
      final from = DateTime(
          effectiveFrom!.year, effectiveFrom!.month, effectiveFrom!.day);
      if (d.isBefore(from)) return false;
    }
    if (effectiveUntil != null) {
      final until = DateTime(
          effectiveUntil!.year, effectiveUntil!.month, effectiveUntil!.day);
      if (!d.isBefore(until)) return false; // until is exclusive
    }
    return true;
  }

  /// Human-readable "1:00 PM – 10:00 PM"
  String get displayTime =>
      '${_fmt12h(startTime)} – ${_fmt12h(endTime)}';

  static String _fmt12h(String hhmm) {
    try {
      final parts = hhmm.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final period = h < 12 ? 'AM' : 'PM';
      final h12 = h % 12 == 0 ? 12 : h % 12;
      return m == 0
          ? '$h12 $period'
          : '$h12:${m.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return hhmm;
    }
  }

  // ── Firestore ──────────────────────────────────────────────────────────────
  factory WorkSchedule.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return WorkSchedule(
      id: doc.id,
      userId: d['userId'] ?? '',
      name: d['name'] ?? '',
      startTime: d['startTime'] ?? '13:00',
      endTime: d['endTime'] ?? '22:00',
      requiredOdcMinutes: d['requiredOdcMinutes'] ?? 480,
      allowedBreakMinutes: d['allowedBreakMinutes'] ?? 60,
      effectiveFrom: d['effectiveFrom'] != null
          ? (d['effectiveFrom'] as Timestamp).toDate()
          : null,
      effectiveUntil: d['effectiveUntil'] != null
          ? (d['effectiveUntil'] as Timestamp).toDate()
          : null,
      enabled: d['enabled'] ?? true,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      updatedAt: (d['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'startTime': startTime,
        'endTime': endTime,
        'requiredOdcMinutes': requiredOdcMinutes,
        'allowedBreakMinutes': allowedBreakMinutes,
        'effectiveFrom': effectiveFrom != null
            ? Timestamp.fromDate(effectiveFrom!)
            : null,
        'effectiveUntil': effectiveUntil != null
            ? Timestamp.fromDate(effectiveUntil!)
            : null,
        'enabled': enabled,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  WorkSchedule copyWith({
    String? name,
    String? startTime,
    String? endTime,
    int? requiredOdcMinutes,
    int? allowedBreakMinutes,
    DateTime? effectiveFrom,
    DateTime? effectiveUntil,
    bool? enabled,
    DateTime? updatedAt,
  }) =>
      WorkSchedule(
        id: id,
        userId: userId,
        name: name ?? this.name,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        requiredOdcMinutes: requiredOdcMinutes ?? this.requiredOdcMinutes,
        allowedBreakMinutes: allowedBreakMinutes ?? this.allowedBreakMinutes,
        effectiveFrom: effectiveFrom ?? this.effectiveFrom,
        effectiveUntil: effectiveUntil ?? this.effectiveUntil,
        enabled: enabled ?? this.enabled,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Default Schedule A: 1 PM – 10 PM
  static WorkSchedule defaultScheduleA(String userId) => WorkSchedule(
        id: 'schedule_a',
        userId: userId,
        name: 'Schedule A',
        startTime: '13:00',
        endTime: '22:00',
        requiredOdcMinutes: 480,
        allowedBreakMinutes: 60,
        effectiveFrom: null,
        effectiveUntil: null,
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  /// Default Schedule B: 2 PM – 11 PM
  static WorkSchedule defaultScheduleB(String userId) => WorkSchedule(
        id: 'schedule_b',
        userId: userId,
        name: 'Schedule B',
        startTime: '14:00',
        endTime: '23:00',
        requiredOdcMinutes: 480,
        allowedBreakMinutes: 60,
        effectiveFrom: null,
        effectiveUntil: null,
        enabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}
