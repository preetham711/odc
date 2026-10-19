import 'package:cloud_firestore/cloud_firestore.dart';

/// Comprehensive monthly report for end-of-month summaries
class MonthlyReportModel {
  final String id;
  final String userId;
  final String userName;
  final int year;
  final int month;

  // Working days and attendance
  final int totalWorkingDays; // Business days in month
  final int daysPresent; // Days with attendance
  final int daysAbsent; // Working days without attendance
  final int daysOnLeave; // Approved leave days
  final double attendancePercentage;

  // Time tracking
  final int totalODCMinutes;
  final int totalBreakMinutes;
  final int expectedODCMinutes; // Based on working days and daily goal
  final int overtimeMinutes; // Minutes beyond expected
  final int undertimeMinutes; // Minutes short of expected
  final double goalCompletionRate; // Percentage of expected time achieved

  // Session analysis
  final int totalSessions; // Total ODC + break sessions
  final int avgSessionDuration; // Average session length in minutes
  final int longestSession; // Longest ODC session
  final int shortestSession; // Shortest ODC session

  // Break analysis
  final int totalBreakSessions;
  final int avgBreakDuration;
  final int longestBreak;
  final int breakViolations; // Days where break exceeded limit

  // Punctuality
  final int onTimeDays; // Check-in within 15 min of shift start
  final int lateDays; // Check-in after 15 min grace period
  final int avgLateMinutes; // Average lateness in minutes
  final int earlyCheckouts; // Check-out before shift end

  // Perfect days tracking
  final int perfectDays; // 100%+ completion, no violations
  final int goodDays; // 80-99% completion
  final int belowAverageDays; // <80% completion

  // Timestamps
  final DateTime generatedAt;

  // Detailed day-by-day breakdown (optional, for exports)
  final List<DailyBreakdown>? dailyBreakdown;

  const MonthlyReportModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.year,
    required this.month,
    required this.totalWorkingDays,
    required this.daysPresent,
    required this.daysAbsent,
    required this.daysOnLeave,
    required this.attendancePercentage,
    required this.totalODCMinutes,
    required this.totalBreakMinutes,
    required this.expectedODCMinutes,
    required this.overtimeMinutes,
    required this.undertimeMinutes,
    required this.goalCompletionRate,
    required this.totalSessions,
    required this.avgSessionDuration,
    required this.longestSession,
    required this.shortestSession,
    required this.totalBreakSessions,
    required this.avgBreakDuration,
    required this.longestBreak,
    required this.breakViolations,
    required this.onTimeDays,
    required this.lateDays,
    required this.avgLateMinutes,
    required this.earlyCheckouts,
    required this.perfectDays,
    required this.goodDays,
    required this.belowAverageDays,
    required this.generatedAt,
    this.dailyBreakdown,
  });

  // Computed properties
  String get monthName {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  String get periodDisplay => '$monthName $year';

  double get avgODCHoursPerDay =>
      daysPresent > 0 ? (totalODCMinutes / daysPresent / 60) : 0.0;

  String get totalODCFormatted {
    final hours = totalODCMinutes ~/ 60;
    final mins = totalODCMinutes % 60;
    return '${hours}h ${mins}m';
  }

  String get overtimeFormatted {
    final hours = overtimeMinutes ~/ 60;
    final mins = overtimeMinutes % 60;
    return overtimeMinutes > 0 ? '+${hours}h ${mins}m' : '0h';
  }

  String get undertimeFormatted {
    final hours = undertimeMinutes ~/ 60;
    final mins = undertimeMinutes % 60;
    return undertimeMinutes > 0 ? '-${hours}h ${mins}m' : '0h';
  }

  // Performance grade
  String get performanceGrade {
    if (goalCompletionRate >= 95 && breakViolations == 0 && lateDays <= 2) {
      return 'Excellent';
    } else if (goalCompletionRate >= 85 && breakViolations <= 3) {
      return 'Good';
    } else if (goalCompletionRate >= 75) {
      return 'Average';
    } else {
      return 'Below Average';
    }
  }

  factory MonthlyReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MonthlyReportModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      year: data['year'] ?? 0,
      month: data['month'] ?? 0,
      totalWorkingDays: data['totalWorkingDays'] ?? 0,
      daysPresent: data['daysPresent'] ?? 0,
      daysAbsent: data['daysAbsent'] ?? 0,
      daysOnLeave: data['daysOnLeave'] ?? 0,
      attendancePercentage: (data['attendancePercentage'] ?? 0.0).toDouble(),
      totalODCMinutes: data['totalODCMinutes'] ?? 0,
      totalBreakMinutes: data['totalBreakMinutes'] ?? 0,
      expectedODCMinutes: data['expectedODCMinutes'] ?? 0,
      overtimeMinutes: data['overtimeMinutes'] ?? 0,
      undertimeMinutes: data['undertimeMinutes'] ?? 0,
      goalCompletionRate: (data['goalCompletionRate'] ?? 0.0).toDouble(),
      totalSessions: data['totalSessions'] ?? 0,
      avgSessionDuration: data['avgSessionDuration'] ?? 0,
      longestSession: data['longestSession'] ?? 0,
      shortestSession: data['shortestSession'] ?? 0,
      totalBreakSessions: data['totalBreakSessions'] ?? 0,
      avgBreakDuration: data['avgBreakDuration'] ?? 0,
      longestBreak: data['longestBreak'] ?? 0,
      breakViolations: data['breakViolations'] ?? 0,
      onTimeDays: data['onTimeDays'] ?? 0,
      lateDays: data['lateDays'] ?? 0,
      avgLateMinutes: data['avgLateMinutes'] ?? 0,
      earlyCheckouts: data['earlyCheckouts'] ?? 0,
      perfectDays: data['perfectDays'] ?? 0,
      goodDays: data['goodDays'] ?? 0,
      belowAverageDays: data['belowAverageDays'] ?? 0,
      generatedAt: (data['generatedAt'] as Timestamp).toDate(),
      dailyBreakdown: (data['dailyBreakdown'] as List<dynamic>?)
          ?.map((e) => DailyBreakdown.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'year': year,
      'month': month,
      'totalWorkingDays': totalWorkingDays,
      'daysPresent': daysPresent,
      'daysAbsent': daysAbsent,
      'daysOnLeave': daysOnLeave,
      'attendancePercentage': attendancePercentage,
      'totalODCMinutes': totalODCMinutes,
      'totalBreakMinutes': totalBreakMinutes,
      'expectedODCMinutes': expectedODCMinutes,
      'overtimeMinutes': overtimeMinutes,
      'undertimeMinutes': undertimeMinutes,
      'goalCompletionRate': goalCompletionRate,
      'totalSessions': totalSessions,
      'avgSessionDuration': avgSessionDuration,
      'longestSession': longestSession,
      'shortestSession': shortestSession,
      'totalBreakSessions': totalBreakSessions,
      'avgBreakDuration': avgBreakDuration,
      'longestBreak': longestBreak,
      'breakViolations': breakViolations,
      'onTimeDays': onTimeDays,
      'lateDays': lateDays,
      'avgLateMinutes': avgLateMinutes,
      'earlyCheckouts': earlyCheckouts,
      'perfectDays': perfectDays,
      'goodDays': goodDays,
      'belowAverageDays': belowAverageDays,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'dailyBreakdown':
          dailyBreakdown?.map((e) => e.toMap()).toList(),
    };
  }
}

/// Daily breakdown for detailed monthly report
class DailyBreakdown {
  final DateTime date;
  final bool isPresent;
  final bool isLeave;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int odcMinutes;
  final int breakMinutes;
  final int sessions;
  final bool isLate;
  final bool breakViolation;
  final double completionPercentage;

  const DailyBreakdown({
    required this.date,
    required this.isPresent,
    required this.isLeave,
    this.checkIn,
    this.checkOut,
    required this.odcMinutes,
    required this.breakMinutes,
    required this.sessions,
    required this.isLate,
    required this.breakViolation,
    required this.completionPercentage,
  });

  factory DailyBreakdown.fromMap(Map<String, dynamic> map) {
    return DailyBreakdown(
      date: (map['date'] as Timestamp).toDate(),
      isPresent: map['isPresent'] ?? false,
      isLeave: map['isLeave'] ?? false,
      checkIn:
          map['checkIn'] != null ? (map['checkIn'] as Timestamp).toDate() : null,
      checkOut: map['checkOut'] != null
          ? (map['checkOut'] as Timestamp).toDate()
          : null,
      odcMinutes: map['odcMinutes'] ?? 0,
      breakMinutes: map['breakMinutes'] ?? 0,
      sessions: map['sessions'] ?? 0,
      isLate: map['isLate'] ?? false,
      breakViolation: map['breakViolation'] ?? false,
      completionPercentage: (map['completionPercentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'isPresent': isPresent,
      'isLeave': isLeave,
      'checkIn': checkIn != null ? Timestamp.fromDate(checkIn!) : null,
      'checkOut': checkOut != null ? Timestamp.fromDate(checkOut!) : null,
      'odcMinutes': odcMinutes,
      'breakMinutes': breakMinutes,
      'sessions': sessions,
      'isLate': isLate,
      'breakViolation': breakViolation,
      'completionPercentage': completionPercentage,
    };
  }
}

/// Company-wide monthly summary (for admin)
class CompanyMonthlyReport {
  final int year;
  final int month;
  final int totalEmployees;
  final double avgAttendanceRate;
  final int totalODCHours;
  final int totalOvertimeHours;
  final int totalLeavesDays;
  final int perfectEmployees; // Employees with 95%+ completion
  final List<MonthlyReportModel> employeeReports;
  final DateTime generatedAt;

  const CompanyMonthlyReport({
    required this.year,
    required this.month,
    required this.totalEmployees,
    required this.avgAttendanceRate,
    required this.totalODCHours,
    required this.totalOvertimeHours,
    required this.totalLeavesDays,
    required this.perfectEmployees,
    required this.employeeReports,
    required this.generatedAt,
  });

  String get periodDisplay {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[month - 1]} $year';
  }
}
