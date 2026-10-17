import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/admin_service.dart';
import 'auth_provider.dart';

final adminServiceProvider = Provider((_) => AdminService());

/// Is the currently signed-in user an admin?
final isAdminProvider = FutureProvider<bool>((ref) async {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return false;
  try {
    final profile = await ref.read(authServiceProvider).getUserProfile(uid);
    return profile.isAdmin;
  } catch (_) {
    return false;
  }
});

/// Stream of all users — admin only.
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;
  if (!isAdmin) return const Stream.empty();
  return ref.read(adminServiceProvider).streamAllUsers();
});

/// Admin dashboard stats — refreshed manually.
final adminStatsProvider = FutureProvider<AdminStats?>((ref) async {
  final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;
  if (!isAdmin) return null;
  return ref.read(adminServiceProvider).getAdminStats();
});

/// Stats for a single user (family provider).
final userStatsProvider =
    FutureProvider.family<UserStats, String>((ref, uid) async {
  final now = DateTime.now();
  return ref.read(adminServiceProvider).getUserStats(
        uid,
        from: DateTime(now.year, now.month, 1),
        to: now,
      );
});

/// Today's live attendance for a single user (admin view).
final userTodayAttendanceProvider =
    StreamProvider.family<AttendanceModel?, String>((ref, uid) {
  return ref
      .read(adminServiceProvider)
      .streamUserTodayAttendance(uid);
});
