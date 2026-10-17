import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/work_schedule.dart';
import 'auth_provider.dart';

// ─── Stream of all user schedules ─────────────────────────────────────────────
final schedulesProvider = StreamProvider<List<WorkSchedule>>((ref) {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).streamSchedules(uid);
});

// ─── Active schedule for today ─────────────────────────────────────────────────
final activeScheduleProvider = FutureProvider<WorkSchedule?>((ref) async {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return null;
  return ref.read(firestoreServiceProvider).getScheduleForDate(uid, DateTime.now());
});

// ─── Active schedule for a specific date (family) ─────────────────────────────
final scheduleForDateProvider =
    FutureProvider.family<WorkSchedule?, DateTime>((ref, date) async {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return null;
  return ref.read(firestoreServiceProvider).getScheduleForDate(uid, date);
});

// ─── Schedule notifier ─────────────────────────────────────────────────────────
class ScheduleNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> save(WorkSchedule schedule) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    await ref.read(firestoreServiceProvider).saveSchedule(uid, schedule);
    ref.invalidate(schedulesProvider);
    ref.invalidate(activeScheduleProvider);
  }

  Future<void> delete(String scheduleId) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    await ref.read(firestoreServiceProvider).deleteSchedule(uid, scheduleId);
    ref.invalidate(schedulesProvider);
    ref.invalidate(activeScheduleProvider);
  }
}

final scheduleNotifierProvider =
    NotifierProvider<ScheduleNotifier, void>(ScheduleNotifier.new);
