import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 6)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime? dueDate;

  @HiveField(5)
  TaskPriority priority;

  @HiveField(6)
  bool isCompleted;

  @HiveField(7)
  DateTime? completedAt;

  @HiveField(8)
  bool hasReminder;

  @HiveField(9)
  DateTime? reminderTime;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
    this.completedAt,
    this.hasReminder = false,
    this.reminderTime,
  });

  bool isOverdue() {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  bool isDueToday() {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }
}

@HiveType(typeId: 7)
enum TaskPriority {
  @HiveField(0)
  low,

  @HiveField(1)
  medium,

  @HiveField(2)
  high,

  @HiveField(3)
  urgent,
}
