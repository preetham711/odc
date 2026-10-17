import '../models/work_schedule.dart';

/// Service to validate if current time is within work schedule
class ScheduleValidatorService {
  /// Check if current time is within the schedule's work hours
  /// Returns null if valid, error message if invalid
  String? validateCurrentTime(WorkSchedule? schedule) {
    if (schedule == null) {
      return 'No work schedule found. Please set up your schedule first.';
    }

    if (!schedule.enabled) {
      return 'Your work schedule is currently disabled.';
    }

    final now = DateTime.now();
    
    // Check if schedule is active for today
    if (!schedule.isActiveOn(now)) {
      return 'This schedule is not active today.';
    }

    // Parse schedule times
    final startParts = schedule.startTime.split(':');
    final endParts = schedule.endTime.split(':');
    
    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);
    final endHour = int.parse(endParts[0]);
    final endMinute = int.parse(endParts[1]);

    // Create DateTime objects for comparison
    final scheduleStart = DateTime(
      now.year,
      now.month,
      now.day,
      startHour,
      startMinute,
    );
    
    // Handle end time that goes into next day
    final scheduleEnd = DateTime(
      now.year,
      now.month,
      now.day + (endHour < startHour ? 1 : 0),
      endHour,
      endMinute,
    );

    // Check if current time is within schedule
    if (now.isBefore(scheduleStart)) {
      final minutesUntilStart = scheduleStart.difference(now).inMinutes;
      final hoursUntilStart = minutesUntilStart ~/ 60;
      final remainingMinutes = minutesUntilStart % 60;
      
      return 'Work hours start at ${schedule.displayTime.split(' – ').first}. '
          'Please wait ${hoursUntilStart > 0 ? '$hoursUntilStart hour${hoursUntilStart > 1 ? 's' : ''} ' : ''}'
          '${remainingMinutes > 0 ? '$remainingMinutes minute${remainingMinutes > 1 ? 's' : ''}' : ''}.';
    }

    if (now.isAfter(scheduleEnd)) {
      return 'Work hours ended at ${schedule.displayTime.split(' – ').last}. '
          'You cannot track time outside your scheduled hours.';
    }

    // Valid - within schedule
    return null;
  }

  /// Get formatted time remaining in schedule
  String getTimeRemainingInSchedule(WorkSchedule schedule) {
    final now = DateTime.now();
    final endParts = schedule.endTime.split(':');
    final endHour = int.parse(endParts[0]);
    final endMinute = int.parse(endParts[1]);
    
    final startParts = schedule.startTime.split(':');
    final startHour = int.parse(startParts[0]);

    final scheduleEnd = DateTime(
      now.year,
      now.month,
      now.day + (endHour < startHour ? 1 : 0),
      endHour,
      endMinute,
    );

    final remaining = scheduleEnd.difference(now);
    if (remaining.isNegative) return '0h 0m';

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  /// Check if we're approaching end of schedule (within 30 minutes)
  bool isApproachingScheduleEnd(WorkSchedule schedule) {
    final now = DateTime.now();
    final endParts = schedule.endTime.split(':');
    final endHour = int.parse(endParts[0]);
    final endMinute = int.parse(endParts[1]);
    
    final startParts = schedule.startTime.split(':');
    final startHour = int.parse(startParts[0]);

    final scheduleEnd = DateTime(
      now.year,
      now.month,
      now.day + (endHour < startHour ? 1 : 0),
      endHour,
      endMinute,
    );

    final remaining = scheduleEnd.difference(now);
    return remaining.inMinutes <= 30 && remaining.inMinutes > 0;
  }
}
