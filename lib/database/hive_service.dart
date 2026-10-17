import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/odc_session.dart';
import '../models/note.dart';
import '../models/task.dart';

class HiveService {
  static const String odcSessionBox = 'odc_sessions';
  static const String notesBox = 'notes';
  static const String tasksBox = 'tasks';
  static const String settingsBox = 'settings';

  static Future<void> init() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ODCSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(BreakSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TimelineEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TimelineEntryTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(NoteAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(ChecklistItemAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(TaskAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(TaskPriorityAdapter());
    }

    // Open boxes
    await Hive.openBox<ODCSession>(odcSessionBox);
    await Hive.openBox<Note>(notesBox);
    await Hive.openBox<Task>(tasksBox);
    await Hive.openBox(settingsBox);
  }

  static Box<ODCSession> getODCSessionBox() {
    return Hive.box<ODCSession>(odcSessionBox);
  }

  static Box<Note> getNotesBox() {
    return Hive.box<Note>(notesBox);
  }

  static Box<Task> getTasksBox() {
    return Hive.box<Task>(tasksBox);
  }

  static Box getSettingsBox() {
    return Hive.box(settingsBox);
  }

  static Future<void> close() async {
    await Hive.close();
  }
}
