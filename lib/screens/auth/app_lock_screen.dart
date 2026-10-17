import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/biometric_provider.dart';
import '../../services/ios_features_service.dart';
import '../../theme/app_theme.dart';

/// Shown over the app when App Lock is enabled and the session is not unlocked.
class AppLockScreen extends ConsumerStatefulWidget {
  final Widget child;
  const AppLockScreen({super.key, required this.child});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen>
    with WidgetsBindingObserver {
  bool _isAuthenticating = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Attempt auth automatically on first show
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lock again when app comes back from background
    if (state == AppLifecycleState.resumed) {
      final unlocked = ref.read(sessionUnlockedProvider);
      if (!unlocked) _authenticate();
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _failed = false;
    });

    final type = await IOSFeaturesService().biometricType();
    final reason = type == 'faceID'
        ? 'Use Face ID to unlock ODC Tracker AI'
        : type == 'touchID'
            ? 'Use Touch ID to unlock ODC Tracker AI'
            : 'Authenticate to unlock ODC Tracker AI';

    final success = await IOSFeaturesService().authenticate(reason: reason);

    if (!mounted) return;
    setState(() => _isAuthenticating = false);

    if (success) {
      await IOSFeaturesService.successFeedback();
      ref.read(sessionUnlockedProvider.notifier).state = true;
    } else {
      await IOSFeaturesService.errorFeedback();
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = ref.watch(sessionUnlockedProvider);
    if (unlocked) return widget.child;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.accentDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: AppShadows.elevated(AppColors.accent),
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                )
                    .animate()
                    .scale(duration: 500.ms, curve: Curves.easeOut),

                const SizedBox(height: 32),

                Text(
                  'ODC Tracker AI',
                  style: theme.textTheme.headlineMedium,
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 8),

                Text(
                  'Locked',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.label3Dark : AppColors.label3Light,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 48),

                // Biometric button
                FutureBuilder<String>(
                  future: IOSFeaturesService().biometricType(),
                  builder: (context, snapshot) {
                    final type = snapshot.data ?? 'none';
                    final icon = type == 'faceID'
                        ? Icons.face_rounded
                        : type == 'touchID'
                            ? Icons.fingerprint_rounded
                            : Icons.lock_open_rounded;
                    final label = type == 'faceID'
                        ? 'Unlock with Face ID'
                        : type == 'touchID'
                            ? 'Unlock with Touch ID'
                            : 'Authenticate';

                    return Column(
                      children: [
                        GestureDetector(
                          onTap: _isAuthenticating ? null : _authenticate,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: _failed
                                  ? AppColors.danger.withValues(alpha: 0.15)
                                  : AppColors.accent.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: _isAuthenticating
                                ? const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.accent,
                                    ),
                                  )
                                : Icon(
                                    icon,
                                    size: 36,
                                    color: _failed
                                        ? AppColors.danger
                                        : AppColors.accent,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _failed ? 'Authentication failed — try again' : label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _failed ? AppColors.danger : AppColors.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
