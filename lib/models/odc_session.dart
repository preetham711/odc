import 'package:hive/hive.dart';

part 'odc_session.g.dart';

@HiveType(typeId: 0)
class ODCSession extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  DateTime? checkInTime;

  @HiveField(3)
  DateTime? checkOutTime;

  @HiveField(4)
  List<BreakSession> breaks;

  @HiveField(5)
  int totalODCMinutes;

  @HiveField(6)
  int totalBreakMinutes;

  @HiveField(7)
  bool isActive;

  @HiveField(8)
  bool isOnBreak;

  ODCSession({
    required this.id,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.breaks,
    this.totalODCMinutes = 0,
    this.totalBreakMinutes = 0,
    this.isActive = false,
    this.isOnBreak = false,
  });

  // Calculate total ODC time
  int calculateODCTime() {
    if (checkInTime == null) return 0;
    
    DateTime endTime = checkOutTime ?? DateTime.now();
    int totalMinutes = endTime.difference(checkInTime!).inMinutes;
    
    // Subtract break time
    int breakMinutes = breaks.fold(0, (sum, breakSession) {
      if (breakSession.startTime != null) {
        DateTime breakEnd = breakSession.endTime ?? DateTime.now();
        return sum + breakEnd.difference(breakSession.startTime!).inMinutes;
      }
      return sum;
    });
    
    return totalMinutes - breakMinutes;
  }

  // Calculate total break time
  int calculateBreakTime() {
    return breaks.fold(0, (sum, breakSession) {
      if (breakSession.startTime != null) {
        DateTime breakEnd = breakSession.endTime ?? DateTime.now();
        return sum + breakEnd.difference(breakSession.startTime!).inMinutes;
      }
      return sum;
    });
  }

  // Check if daily goal is completed (8 hours = 480 minutes)
  bool isGoalCompleted() {
    return totalODCMinutes >= 480;
  }

  // Get completion percentage
  double getCompletionPercentage() {
    return (totalODCMinutes / 480) * 100;
  }

  // Get remaining ODC time in minutes
  int getRemainingODC() {
    int remaining = 480 - totalODCMinutes;
    return remaining > 0 ? remaining : 0;
  }

  // Get remaining break time in minutes (max 60 minutes)
  int getRemainingBreak() {
    int remaining = 60 - totalBreakMinutes;
    return remaining > 0 ? remaining : 0;
  }
}

@HiveType(typeId: 1)
class BreakSession extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime? startTime;

  @HiveField(2)
  DateTime? endTime;

  @HiveField(3)
  int durationMinutes;

  BreakSession({
    required this.id,
    this.startTime,
    this.endTime,
    this.durationMinutes = 0,
  });

  int calculateDuration() {
    if (startTime == null) return 0;
    DateTime end = endTime ?? DateTime.now();
    return end.difference(startTime!).inMinutes;
  }
}

@HiveType(typeId: 2)
class TimelineEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime timestamp;

  @HiveField(2)
  TimelineEntryType type;

  @HiveField(3)
  String description;

  TimelineEntry({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.description,
  });
}

@HiveType(typeId: 3)
enum TimelineEntryType {
  @HiveField(0)
  checkIn,

  @HiveField(1)
  checkOut,

  @HiveField(2)
  breakStart,

  @HiveField(3)
  breakEnd,
}
