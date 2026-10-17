import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 4)
class Note extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  @HiveField(5)
  bool isPinned;

  @HiveField(6)
  String? category;

  @HiveField(7)
  List<String> tags;

  @HiveField(8)
  List<ChecklistItem> checklist;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.category,
    this.tags = const [],
    this.checklist = const [],
  });
}

@HiveType(typeId: 5)
class ChecklistItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String text;

  @HiveField(2)
  bool isCompleted;

  ChecklistItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
  });
}
