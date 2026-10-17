import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../core/main_layout.dart';
import 'auth/login_screen.dart';
import '../theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), _navigate);
  }

  void _navigate() {
    if (!mounted || _navigated) return;
    final authState = ref.read(authStateProvider);
    authState.whenData((user) {
      if (user != null) {
        ref.read(firestoreServiceProvider).seedDefaultSchedules(user.uid);
      }
      _go(user != null);
    });
    if (authState.isLoading) {
      Future.delayed(const Duration(milliseconds: 800), _navigate);
    }
    if (authState.hasError) {
      _go(false);
    }
  }

  void _go(bool loggedIn) {
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            loggedIn ? const MainLayout() : const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, next) {
      next.whenData((user) {
        if (!_navigated) {
          if (user != null) {
            ref.read(firestoreServiceProvider).seedDefaultSchedules(user.uid);
          }
          _go(user != null);
        }
      });
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: AppShadows.elevated(AppColors.accent),
              ),
              child: const Icon(
                Icons.access_time_rounded,
                size: 52,
                color: Colors.white,
              ),
            )
                .animate()
                .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1.0, 1.0),
                    duration: 500.ms,
                    curve: Curves.easeOut),
            const SizedBox(height: 24),
            Text(
              'ODC Tracker AI',
              style: Theme.of(context).textTheme.headlineLarge,
            ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
            const SizedBox(height: 8),
            Text(
              'Your work, tracked precisely',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.label3Dark : AppColors.label3Light,
                  ),
            ).animate().fadeIn(delay: 350.ms, duration: 500.ms),
            const SizedBox(height: 64),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent.withValues(alpha: 0.5),
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
