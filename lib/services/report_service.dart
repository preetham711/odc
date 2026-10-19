import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/attendance_model.dart';
import '../models/monthly_report_model.dart';
import '../models/user_model.dart';
import '../models/leave_model.dart';
import 'leave_service.dart';

/// Comprehensive reporting service for end-of-month reports and analytics
class ReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LeaveService _leaveService = LeaveService();

  // ═══════════════════════════════════════════════════════════════════════════
  // MONTHLY REPORT GENERATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate comprehensive monthly report for a user
  Future<MonthlyReportModel> generateMonthlyReport({
    required String userId,
    required String userName,
    required int year,
    required int month,
    required int dailyGoalMinutes,
    required int breakLimitMinutes,
  }) async {
    try {
      // Date range for the month
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59); // Last day of month

      // Get attendance records for the month
      final attendanceQuery = await _db
          .collection('users')
          .doc(userId)
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date')
          .get();

      final attendanceRecords =
          attendanceQuery.docs.map(AttendanceModel.fromFirestore).toList();

      // Get approved leaves for the month
      final leavesQuery = await _db
          .collection('users')
          .doc(userId)
          .collection('leaves')
          .where('status', isEqualTo: LeaveStatus.approved.name)
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();

      final approvedLeaves = leavesQuery.docs.map(LeaveModel.fromFirestore).toList();

      // Calculate working days (excluding weekends)
      final totalWorkingDays = _countWorkingDays(startDate, endDate);

      // Calculate leave days in this month
      int daysOnLeave = 0;
      for (final leave in approvedLeaves) {
        final leaveStart = leave.startDate.isBefore(startDate) ? startDate : leave.startDate;
        final leaveEnd = leave.endDate.isAfter(endDate) ? endDate : leave.endDate;
        daysOnLeave += _countWorkingDays(leaveStart, leaveEnd);
      }

      // Initialize metrics
      int daysPresent = 0;
      int totalODCMinutes = 0;
      int totalBreakMinutes = 0;
      int totalSessions = 0;
      int totalBreakSessions = 0;
      int breakViolations = 0;
      int onTimeDays = 0;
      int lateDays = 0;
      int totalLateMinutes = 0;
      int earlyCheckouts = 0;
      int perfectDays = 0;
      int goodDays = 0;
      int belowAverageDays = 0;

      List<int> sessionDurations = [];
      List<int> breakDurations = [];
      List<DailyBreakdown> dailyBreakdown = [];

      // Process each attendance record
      for (final att in attendanceRecords) {
        if (att.checkIn != null) {
          daysPresent++;
          totalODCMinutes += att.odcTime;
          totalBreakMinutes += att.breakTime;

          // Session analysis
          for (final session in att.sessions) {
            totalSessions++;
            if (session.type == 'odc' && session.duration > 0) {
              sessionDurations.add(session.duration);
            } else if (session.type == 'break') {
              totalBreakSessions++;
              if (session.duration > 0) {
                breakDurations.add(session.duration);
              }
            }
          }

          // Break violations
          if (att.breakTime > breakLimitMinutes) {
            breakViolations++;
          }

          // Punctuality check (assumed shift start from work schedule)
          // For simplicity, we'll check if check-in is close to shift start
          // This requires schedule data - skipping for now or use default
          // TODO: Integrate with work_schedule

          // Perfect/Good/Below average days
          if (att.completionPercentage >= 100) {
            perfectDays++;
          } else if (att.completionPercentage >= 80) {
            goodDays++;
          } else {
            belowAverageDays++;
          }

          // Daily breakdown
          dailyBreakdown.add(DailyBreakdown(
            date: att.date,
            isPresent: true,
            isLeave: false,
            checkIn: att.checkIn,
            checkOut: att.checkOut,
            odcMinutes: att.odcTime,
            breakMinutes: att.breakTime,
            sessions: att.sessions.length,
            isLate: false, // TODO: Calculate based on schedule
            breakViolation: att.breakTime > breakLimitMinutes,
            completionPercentage: att.completionPercentage,
          ));
        }
      }

      // Add leave days to daily breakdown
      for (final leave in approvedLeaves) {
        var currentDate = leave.startDate.isBefore(startDate) ? startDate : leave.startDate;
        final leaveEndDate = leave.endDate.isAfter(endDate) ? endDate : leave.endDate;

        while (currentDate.isBefore(leaveEndDate) ||
            currentDate.isAtSameMomentAs(leaveEndDate)) {
          // Skip weekends
          if (currentDate.weekday != DateTime.saturday &&
              currentDate.weekday != DateTime.sunday) {
            // Check if not already in breakdown (attendance took precedence)
            final existsInBreakdown = dailyBreakdown.any(
              (d) =>
                  d.date.year == currentDate.year &&
                  d.date.month == currentDate.month &&
                  d.date.day == currentDate.day,
            );

            if (!existsInBreakdown) {
              dailyBreakdown.add(DailyBreakdown(
                date: currentDate,
                isPresent: false,
                isLeave: true,
                odcMinutes: 0,
                breakMinutes: 0,
                sessions: 0,
                isLate: false,
                breakViolation: false,
                completionPercentage: 0,
              ));
            }
          }
          currentDate = currentDate.add(const Duration(days: 1));
        }
      }

      // Sort daily breakdown by date
      dailyBreakdown.sort((a, b) => a.date.compareTo(b.date));

      // Calculate averages
      final avgSessionDuration =
          sessionDurations.isNotEmpty ? _average(sessionDurations) : 0;
      final longestSession = sessionDurations.isNotEmpty ? _max(sessionDurations) : 0;
      final shortestSession = sessionDurations.isNotEmpty ? _min(sessionDurations) : 0;
      final avgBreakDuration =
          breakDurations.isNotEmpty ? _average(breakDurations) : 0;
      final longestBreak = breakDurations.isNotEmpty ? _max(breakDurations) : 0;
      final avgLateMinutes = lateDays > 0 ? totalLateMinutes ~/ lateDays : 0;

      // Calculate expected ODC and overtime
      final effectiveWorkingDays = totalWorkingDays - daysOnLeave;
      final expectedODCMinutes = effectiveWorkingDays * dailyGoalMinutes;
      final overtimeMinutes =
          totalODCMinutes > expectedODCMinutes ? totalODCMinutes - expectedODCMinutes : 0;
      final undertimeMinutes =
          totalODCMinutes < expectedODCMinutes ? expectedODCMinutes - totalODCMinutes : 0;

      // Calculate attendance and completion percentages
      final daysAbsent = effectiveWorkingDays - daysPresent;
      final attendancePercentage = effectiveWorkingDays > 0
          ? (daysPresent / effectiveWorkingDays * 100)
          : 0.0;
      final goalCompletionRate = expectedODCMinutes > 0
          ? (totalODCMinutes / expectedODCMinutes * 100)
          : 0.0;

      // Create report
      final report = MonthlyReportModel(
        id: '${userId}_${year}_$month',
        userId: userId,
        userName: userName,
        year: year,
        month: month,
        totalWorkingDays: totalWorkingDays,
        daysPresent: daysPresent,
        daysAbsent: daysAbsent,
        daysOnLeave: daysOnLeave,
        attendancePercentage: attendancePercentage,
        totalODCMinutes: totalODCMinutes,
        totalBreakMinutes: totalBreakMinutes,
        expectedODCMinutes: expectedODCMinutes,
        overtimeMinutes: overtimeMinutes,
        undertimeMinutes: undertimeMinutes,
        goalCompletionRate: goalCompletionRate,
        totalSessions: totalSessions,
        avgSessionDuration: avgSessionDuration,
        longestSession: longestSession,
        shortestSession: shortestSession,
        totalBreakSessions: totalBreakSessions,
        avgBreakDuration: avgBreakDuration,
        longestBreak: longestBreak,
        breakViolations: breakViolations,
        onTimeDays: onTimeDays,
        lateDays: lateDays,
        avgLateMinutes: avgLateMinutes,
        earlyCheckouts: earlyCheckouts,
        perfectDays: perfectDays,
        goodDays: goodDays,
        belowAverageDays: belowAverageDays,
        generatedAt: DateTime.now(),
        dailyBreakdown: dailyBreakdown,
      );

      // Save report to Firestore
      await _db
          .collection('monthly_reports')
          .doc(report.id)
          .set(report.toFirestore());

      return report;
    } catch (e) {
      debugPrint('Error generating monthly report: $e');
      rethrow;
    }
  }

  /// Get or generate monthly report
  Future<MonthlyReportModel> getMonthlyReport({
    required String userId,
    required int year,
    required int month,
  }) async {
    try {
      final docId = '${userId}_${year}_$month';
      final doc = await _db.collection('monthly_reports').doc(docId).get();

      if (doc.exists) {
        return MonthlyReportModel.fromFirestore(doc);
      }

      // Generate new report
      final user = await _getUserData(userId);
      return await generateMonthlyReport(
        userId: userId,
        userName: user.fullName,
        year: year,
        month: month,
        dailyGoalMinutes: user.dailyGoal,
        breakLimitMinutes: user.breakLimit,
      );
    } catch (e) {
      debugPrint('Error getting monthly report: $e');
      rethrow;
    }
  }

  /// Stream monthly report
  Stream<MonthlyReportModel?> streamMonthlyReport({
    required String userId,
    required int year,
    required int month,
  }) {
    final docId = '${userId}_${year}_$month';
    return _db.collection('monthly_reports').doc(docId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return MonthlyReportModel.fromFirestore(doc);
    });
  }

  /// Regenerate monthly report (force refresh)
  Future<MonthlyReportModel> regenerateMonthlyReport({
    required String userId,
    required int year,
    required int month,
  }) async {
    final user = await _getUserData(userId);
    return await generateMonthlyReport(
      userId: userId,
      userName: user.fullName,
      year: year,
      month: month,
      dailyGoalMinutes: user.dailyGoal,
      breakLimitMinutes: user.breakLimit,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPANY-WIDE REPORTS (Admin)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate company-wide monthly report
  Future<CompanyMonthlyReport> generateCompanyMonthlyReport({
    required int year,
    required int month,
  }) async {
    try {
      // Get all users
      final usersQuery = await _db.collection('users').get();
      final users = usersQuery.docs.map(UserModel.fromFirestore).toList();

      List<MonthlyReportModel> employeeReports = [];
      int totalODCMinutes = 0;
      int totalOvertimeMinutes = 0;
      int totalLeaveDays = 0;
      double totalAttendanceRate = 0;
      int perfectEmployees = 0;

      // Generate/fetch reports for each user
      for (final user in users) {
        if (user.isDisabled) continue; // Skip disabled users

        try {
          final report = await getMonthlyReport(
            userId: user.uid,
            year: year,
            month: month,
          );

          employeeReports.add(report);
          totalODCMinutes += report.totalODCMinutes;
          totalOvertimeMinutes += report.overtimeMinutes;
          totalLeaveDays += report.daysOnLeave;
          totalAttendanceRate += report.attendancePercentage;

          if (report.goalCompletionRate >= 95) {
            perfectEmployees++;
          }
        } catch (e) {
          debugPrint('Error generating report for ${user.uid}: $e');
        }
      }

      final avgAttendanceRate = employeeReports.isNotEmpty
          ? totalAttendanceRate / employeeReports.length
          : 0.0;

      return CompanyMonthlyReport(
        year: year,
        month: month,
        totalEmployees: employeeReports.length,
        avgAttendanceRate: avgAttendanceRate,
        totalODCHours: totalODCMinutes ~/ 60,
        totalOvertimeHours: totalOvertimeMinutes ~/ 60,
        totalLeavesDays: totalLeaveDays,
        perfectEmployees: perfectEmployees,
        employeeReports: employeeReports,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error generating company monthly report: $e');
      rethrow;
    }
  }

  /// Get all monthly reports with filters (Admin)
  Future<List<MonthlyReportModel>> getAllMonthlyReports({
    int? year,
    int? month,
  }) async {
    try {
      Query query = _db.collection('monthly_reports');

      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }

      if (month != null) {
        query = query.where('month', isEqualTo: month);
      }

      final snapshot = await query.get();
      return snapshot.docs.map(MonthlyReportModel.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error getting all monthly reports: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPORT FUNCTIONALITY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Export monthly report as CSV text
  String exportMonthlyReportAsCSV(MonthlyReportModel report) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('ODC Tracker - Monthly Report');
    buffer.writeln('Employee: ${report.userName}');
    buffer.writeln('Period: ${report.periodDisplay}');
    buffer.writeln('Generated: ${_formatDateTime(report.generatedAt)}');
    buffer.writeln();

    // Summary section
    buffer.writeln('SUMMARY');
    buffer.writeln('Total Working Days,${report.totalWorkingDays}');
    buffer.writeln('Days Present,${report.daysPresent}');
    buffer.writeln('Days Absent,${report.daysAbsent}');
    buffer.writeln('Days On Leave,${report.daysOnLeave}');
    buffer.writeln(
        'Attendance Percentage,${report.attendancePercentage.toStringAsFixed(1)}%');
    buffer.writeln();

    // Time tracking section
    buffer.writeln('TIME TRACKING');
    buffer.writeln('Total ODC Time,${report.totalODCFormatted}');
    buffer.writeln('Total Break Time,${_formatMinutes(report.totalBreakMinutes)}');
    buffer.writeln('Expected ODC Time,${_formatMinutes(report.expectedODCMinutes)}');
    buffer.writeln('Overtime,${report.overtimeFormatted}');
    buffer.writeln('Undertime,${report.undertimeFormatted}');
    buffer.writeln(
        'Goal Completion Rate,${report.goalCompletionRate.toStringAsFixed(1)}%');
    buffer.writeln();

    // Performance section
    buffer.writeln('PERFORMANCE');
    buffer.writeln('Perfect Days (100%+),${report.perfectDays}');
    buffer.writeln('Good Days (80-99%),${report.goodDays}');
    buffer.writeln('Below Average Days (<80%),${report.belowAverageDays}');
    buffer.writeln('Break Violations,${report.breakViolations}');
    buffer.writeln('Late Days,${report.lateDays}');
    buffer.writeln('Early Checkouts,${report.earlyCheckouts}');
    buffer.writeln('Performance Grade,${report.performanceGrade}');
    buffer.writeln();

    // Daily breakdown
    if (report.dailyBreakdown != null && report.dailyBreakdown!.isNotEmpty) {
      buffer.writeln('DAILY BREAKDOWN');
      buffer.writeln(
          'Date,Status,Check In,Check Out,ODC Time,Break Time,Sessions,Completion %');

      for (final day in report.dailyBreakdown!) {
        final status = day.isLeave
            ? 'Leave'
            : day.isPresent
                ? 'Present'
                : 'Absent';
        final checkIn = day.checkIn != null ? _formatTime(day.checkIn!) : '-';
        final checkOut = day.checkOut != null ? _formatTime(day.checkOut!) : '-';
        final odcTime = _formatMinutes(day.odcMinutes);
        final breakTime = _formatMinutes(day.breakMinutes);

        buffer.writeln(
            '${_formatDate(day.date)},$status,$checkIn,$checkOut,$odcTime,$breakTime,${day.sessions},${day.completionPercentage.toStringAsFixed(1)}%');
      }
    }

    return buffer.toString();
  }

  /// Export company report as CSV
  String exportCompanyReportAsCSV(CompanyMonthlyReport report) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('ODC Tracker - Company Monthly Report');
    buffer.writeln('Period: ${report.periodDisplay}');
    buffer.writeln('Generated: ${_formatDateTime(DateTime.now())}');
    buffer.writeln();

    // Summary
    buffer.writeln('COMPANY SUMMARY');
    buffer.writeln('Total Employees,${report.totalEmployees}');
    buffer.writeln(
        'Average Attendance Rate,${report.avgAttendanceRate.toStringAsFixed(1)}%');
    buffer.writeln('Total ODC Hours,${report.totalODCHours}');
    buffer.writeln('Total Overtime Hours,${report.totalOvertimeHours}');
    buffer.writeln('Total Leave Days,${report.totalLeavesDays}');
    buffer.writeln('Perfect Employees (95%+),${report.perfectEmployees}');
    buffer.writeln();

    // Employee details
    buffer.writeln('EMPLOYEE DETAILS');
    buffer.writeln(
        'Employee,Days Present,Days Absent,Days Leave,Total ODC,Overtime,Attendance %,Completion %,Grade');

    for (final emp in report.employeeReports) {
      buffer.writeln(
          '${emp.userName},${emp.daysPresent},${emp.daysAbsent},${emp.daysOnLeave},${emp.totalODCFormatted},${emp.overtimeFormatted},${emp.attendancePercentage.toStringAsFixed(1)}%,${emp.goalCompletionRate.toStringAsFixed(1)}%,${emp.performanceGrade}');
    }

    return buffer.toString();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Count working days (exclude weekends)
  int _countWorkingDays(DateTime start, DateTime end) {
    int count = 0;
    var current = start;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      if (current.weekday != DateTime.saturday &&
          current.weekday != DateTime.sunday) {
        count++;
      }
      current = current.add(const Duration(days: 1));
    }

    return count;
  }

  /// Calculate average from list
  int _average(List<int> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) ~/ values.length;
  }

  /// Get max value
  int _max(List<int> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a > b ? a : b);
  }

  /// Get min value
  int _min(List<int> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a < b ? a : b);
  }

  /// Get user data
  Future<UserModel> _getUserData(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) throw Exception('User not found');
    return UserModel.fromFirestore(doc);
  }

  /// Format minutes as "Xh Ym"
  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  /// Format date as "YYYY-MM-DD"
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Format time as "HH:MM"
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Format datetime
  String _formatDateTime(DateTime dt) {
    return '${_formatDate(dt)} ${_formatTime(dt)}';
  }
}
