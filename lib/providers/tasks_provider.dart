import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import 'auth_provider.dart';

final tasksStreamProvider = StreamProvider<List<Task>>((ref) {
  final userId = ref.watch(currentUserProvider)?.uid;
  if (userId == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).streamTasks(userId);
});
