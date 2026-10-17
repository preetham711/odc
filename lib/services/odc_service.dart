import 'package:uuid/uuid.dart';
import '../database/hive_service.dart';
import '../models/odc_session.dart';
import '../utils/date_utils.dart';

class ODCService {
  final _uuid = const Uuid();

  // Get or create today's session
  Future<ODCSession> getTodaySession() async {
    final box = HiveService.getODCSessionBox();
    final today = DateTimeUtils.startOfDay(DateTime.now());

    // Check if session exists for today
    final existingSession = box.values.firstWhere(
      (session) => DateTimeUtils.isToday(session.date),
      orElse: () => _createNewSession(today),
    );

    return existingSession;
  }

  // Create new session
  ODCSession _createNewSession(DateTime date) {
    return ODCSession(
      id: _uuid.v4(),
      date: date,
      breaks: [],
    );
  }

  // Check in
  Future<void> checkIn() async {
    final session = await getTodaySession();
    
    if (!session.isActive) {
      session.checkInTime = DateTime.now();
      session.isActive = true;
      session.isOnBreak = false;
      await session.save();
    }
  }

  // Check out
  Future<void> checkOut() async {
    final session = await getTodaySession();
    
    if (session.isActive) {
      // End any active break
      if (session.isOnBreak && session.breaks.isNotEmpty) {
        final lastBreak = session.breaks.last;
        if (lastBreak.endTime == null) {
          lastBreak.endTime = DateTime.now();
          lastBreak.durationMinutes = lastBreak.calculateDuration();
        }
      }

      session.checkOutTime = DateTime.now();
      session.isActive = false;
      session.isOnBreak = false;
      session.totalODCMinutes = session.calculateODCTime();
      session.totalBreakMinutes = session.calculateBreakTime();
      await session.save();
    }
  }

  // Start break
  Future<void> startBreak() async {
    final session = await getTodaySession();
    
    if (session.isActive && !session.isOnBreak) {
      final newBreak = BreakSession(
        id: _uuid.v4(),
        startTime: DateTime.now(),
      );
      
      session.breaks.add(newBreak);
      session.isOnBreak = true;
      await session.save();
    }
  }

  // End break
  Future<void> endBreak() async {
    final session = await getTodaySession();
    
    if (session.isOnBreak && session.breaks.isNotEmpty) {
      final lastBreak = session.breaks.last;
      lastBreak.endTime = DateTime.now();
      lastBreak.durationMinutes = lastBreak.calculateDuration();
      
      session.isOnBreak = false;
      session.totalBreakMinutes = session.calculateBreakTime();
      await session.save();
    }
  }

  // Get current ODC time in real-time
  int getCurrentODCTime(ODCSession session) {
    if (!session.isActive || session.checkInTime == null) return 0;
    
    return session.calculateODCTime();
  }

  // Get current break time in real-time
  int getCurrentBreakTime(ODCSession session) {
    if (session.breaks.isEmpty) return 0;
    
    return session.calculateBreakTime();
  }

  // Get session by date
  Future<ODCSession?> getSessionByDate(DateTime date) async {
    final box = HiveService.getODCSessionBox();
    final startDate = DateTimeUtils.startOfDay(date);
    
    try {
      return box.values.firstWhere(
        (session) => DateTimeUtils.startOfDay(session.date).isAtSameMomentAs(startDate),
      );
    } catch (e) {
      return null;
    }
  }

  // Get sessions for date range
  List<ODCSession> getSessionsInRange(DateTime startDate, DateTime endDate) {
    final box = HiveService.getODCSessionBox();
    
    return box.values.where((session) {
      return session.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
             session.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Get weekly sessions
  List<ODCSession> getWeeklySessions() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return getSessionsInRange(startOfWeek, endOfWeek);
  }

  // Get monthly sessions
  List<ODCSession> getMonthlySessions() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return getSessionsInRange(startOfMonth, endOfMonth);
  }

  // Get yearly sessions
  List<ODCSession> getYearlySessions() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31);
    
    return getSessionsInRange(startOfYear, endOfYear);
  }

  // Calculate statistics
  Map<String, dynamic> calculateStatistics(List<ODCSession> sessions) {
    if (sessions.isEmpty) {
      return {
        'totalODC': 0,
        'totalBreak': 0,
        'averageODC': 0.0,
        'perfectDays': 0,
        'completionRate': 0.0,
      };
    }

    int totalODC = 0;
    int totalBreak = 0;
    int perfectDays = 0;

    for (var session in sessions) {
      totalODC += session.totalODCMinutes;
      totalBreak += session.totalBreakMinutes;
      if (session.isGoalCompleted()) {
        perfectDays++;
      }
    }

    return {
      'totalODC': totalODC,
      'totalBreak': totalBreak,
      'averageODC': totalODC / sessions.length,
      'perfectDays': perfectDays,
      'completionRate': (perfectDays / sessions.length) * 100,
    };
  }
}
