import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/hive_service.dart';
import '../services/ios_features_service.dart';

// ─── Biometric availability ───────────────────────────────────────────────────
final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  return IOSFeaturesService().canUseBiometrics();
});

final biometricTypeProvider = FutureProvider<String>((ref) async {
  return IOSFeaturesService().biometricType();
});

// ─── App Lock settings ────────────────────────────────────────────────────────
class AppLockNotifier extends StateNotifier<bool> {
  AppLockNotifier() : super(false) {
    _load();
  }

  void _load() {
    if (kIsWeb) return;
    try {
      final box = HiveService.getSettingsBox();
      state = box.get('app_lock_enabled', defaultValue: false) as bool;
    } catch (_) {}
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    if (kIsWeb) return;
    try {
      final box = HiveService.getSettingsBox();
      await box.put('app_lock_enabled', value);
    } catch (_) {}
  }
}

final appLockEnabledProvider =
    StateNotifierProvider<AppLockNotifier, bool>((_) => AppLockNotifier());

// ─── Auth state for the current session ──────────────────────────────────────
/// True once the user has successfully authenticated this session.
final sessionUnlockedProvider = StateProvider<bool>((ref) {
  // If app lock is disabled, always unlocked
  final lockEnabled = ref.watch(appLockEnabledProvider);
  if (!lockEnabled) return true;
  return false; // starts locked; flipped after biometric succeeds
});
