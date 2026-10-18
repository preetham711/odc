import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifications/notification_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

// Auth service provider
final authServiceProvider = Provider((ref) => AuthService());

// Firestore service provider
final firestoreServiceProvider = Provider((ref) => FirestoreService());

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authServiceProvider).currentUser;
});

// User profile provider - watches auth state and refreshes on change
final userProfileProvider = StreamProvider<UserModel?>((ref) async* {
  final authState = ref.watch(authStateProvider);
  
  final user = authState.value;
  
  if (user == null) {
    yield null;
    return;
  }
  
  try {
    final profile = await ref.read(authServiceProvider).getUserProfile(user.uid);
    debugPrint('✅ Profile loaded: ${profile.fullName}, role: ${profile.role}, isAdmin: ${profile.isAdmin}');
    yield profile;
  } catch (e) {
    debugPrint('❌ Error loading user profile: $e');
    yield null;
  }
});

// Auth notifier
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((user) {
      state = AsyncValue.data(user);
      // Keep NotificationService in sync so reminder events are attributed correctly
      NotificationService().setUserId(user?.uid);
    });
  }

  Future<void> signIn({
    required String mobileNumber,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signIn(
        mobileNumber: mobileNumber,
        password: password,
      );
      // State will be updated by auth state listener
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> signUp({
    required String fullName,
    required String mobileNumber,
    required String password,
    String? email,
    String? employeeId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signUp(
        fullName: fullName,
        mobileNumber: mobileNumber,
        password: password,
        email: email,
        employeeId: employeeId,
      );
      // State will be updated by auth state listener
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword(String mobileNumber) async {
    try {
      await _authService.resetPassword(mobileNumber);
    } catch (e) {
      rethrow;
    }
  }
}

// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
