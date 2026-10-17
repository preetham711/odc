import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note.dart';
import 'auth_provider.dart';

final notesStreamProvider = StreamProvider<List<Note>>((ref) {
  final userId = ref.watch(currentUserProvider)?.uid;
  if (userId == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).streamNotes(userId);
});
