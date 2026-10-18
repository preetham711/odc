import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/biometric_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../services/ios_features_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ios_widgets.dart';
import '../auth/login_screen.dart';
import '../settings/break_reminder_settings_screen.dart';
import '../settings/profile_edit_screen.dart';
import '../settings/work_schedule_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeProvider);
    final userProfile = ref.watch(userProfileProvider);
    
    // Debug: Log the profile state
    userProfile.when(
      data: (user) => debugPrint('Profile loaded: ${user?.fullName}'),
      loading: () => debugPrint('Profile loading...'),
      error: (error, stack) => debugPrint('Profile error: $error'),
    );
    
    final activeSchedule = ref.watch(activeScheduleProvider).valueOrNull;

    // Handle loading state for entire screen
    if (userProfile.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Handle error state for entire screen
    if (userProfile.hasError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
                const SizedBox(height: 16),
                Text(
                  'Error Loading Profile',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  userProfile.error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(userProfileProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHeader(
              userProfile: userProfile,
              isDark: isDark,
            ).animate().fadeIn(duration: 400.ms),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: _ScheduleBanner(
                schedule: activeSchedule,
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const WorkScheduleScreen()),
                ).then((_) {
                  ref.invalidate(schedulesProvider);
                  ref.invalidate(activeScheduleProvider);
                }),
              ),
            ).animate().fadeIn(delay: 80.ms),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Account section
                  _SettingsSection(
                    title: 'Account',
                    isDark: isDark,
                    children: [
                      IOSListRow(
                        leadingIcon: Icons.person_rounded,
                        iconColor: AppColors.accent,
                        title: 'Edit Profile',
                        subtitle: userProfile.when(
                          data: (user) => user?.fullName ?? 'Loading...',
                          loading: () => 'Loading...',
                          error: (_, __) => 'Error loading profile',
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileEditScreen()),
                        ).then((_) => ref.invalidate(userProfileProvider)),
                      ),
                      IOSListRow(
                        leadingIcon: Icons.schedule_rounded,
                        iconColor: AppColors.success,
                        title: 'Work Schedules',
                        subtitle: activeSchedule?.displayTime ??
                            'Configure your shift times',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const WorkScheduleScreen()),
                        ).then((_) {
                          ref.invalidate(schedulesProvider);
                          ref.invalidate(activeScheduleProvider);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Security section (Face ID / Touch ID)
                  if (!kIsWeb)
                    _SecuritySection(isDark: isDark),
                  if (!kIsWeb) const SizedBox(height: 14),

                  // Notifications
                  _SettingsSection(
                    title: 'Notifications',
                    isDark: isDark,
                    children: [
                      IOSListRow(
                        leadingIcon: Icons.notifications_active_rounded,
                        iconColor: AppColors.warning,
                        title: 'Break Reminders',
                        subtitle: 'Configure return reminders while on break',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const BreakReminderSettingsScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Appearance
                  _SettingsSection(
                    title: 'Appearance',
                    isDark: isDark,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.accent
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.palette_rounded,
                                  color: AppColors.accent, size: 17),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text('Theme',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall),
                            ),
                            IOSSegmentedControl<ThemeMode>(
                              selectedValue: themeMode,
                              options: const {
                                ThemeMode.light: '☀️ Light',
                                ThemeMode.dark: '🌙 Dark',
                                ThemeMode.system: 'Auto',
                              },
                              onChanged: (m) =>
                                  ref.read(themeProvider.notifier).setTheme(m),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Share & Rate
                  _SettingsSection(
                    title: 'Share & Rate',
                    isDark: isDark,
                    children: [
                      IOSListRow(
                        leadingIcon: Icons.share_rounded,
                        iconColor: AppColors.accent,
                        title: 'Share ODC Tracker AI',
                        subtitle: 'Tell your team about this app',
                        onTap: () => IOSFeaturesService.shareText(
                          'Check out ODC Tracker AI — a premium time tracking app for ODC employees. Download it now!',
                          subject: 'ODC Tracker AI',
                        ),
                      ),
                      IOSListRow(
                        leadingIcon: Icons.star_rounded,
                        iconColor: AppColors.warning,
                        title: 'Rate on App Store',
                        subtitle: 'Leave a review',
                        onTap: () =>
                            IOSFeaturesService().requestReview(),
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // About
                  _AboutSection(isDark: isDark),
                  const SizedBox(height: 20),

                  // Sign out
                  _SignOutButton(isDark: isDark),
                  const SizedBox(height: 40),
                ],
              ).animate().fadeIn(delay: 150.ms),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Header ───────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final AsyncValue<dynamic> userProfile;
  final bool isDark;

  const _ProfileHeader({required this.userProfile, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return userProfile.when(
      data: (user) {
        final name = user?.fullName ?? 'User';
        final mobile = user?.mobileNumber ?? '';
        final employeeId = user?.employeeId;
        final initials = name.isNotEmpty
            ? name.split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join()
            : 'U';

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withValues(alpha: 0.12),
                AppColors.accent.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Hero(
                tag: 'profile_avatar',
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.accentDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.elevated(AppColors.accent),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              if (mobile.isNotEmpty)
                Text(
                  mobile,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.label3Dark : AppColors.label3Light,
                  ),
                ),
              if (employeeId != null && employeeId.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    'ID: $employeeId',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              'Error loading profile',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Schedule Banner ──────────────────────────────────────────────────────────
class _ScheduleBanner extends StatelessWidget {
  final dynamic schedule;
  final bool isDark;
  final VoidCallback onTap;

  const _ScheduleBanner({
    required this.schedule,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
              color: AppColors.success.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.schedule_rounded,
                  color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule?.name ?? 'Schedule A',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    schedule?.displayTime ?? '1 PM – 10 PM',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.success, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Security Section ─────────────────────────────────────────────────────────
class _SecuritySection extends ConsumerWidget {
  final bool isDark;
  const _SecuritySection({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricType = ref.watch(biometricTypeProvider).valueOrNull ?? 'none';
    final appLockEnabled = ref.watch(appLockEnabledProvider);

    if (biometricType == 'none') return const SizedBox.shrink();

    final icon = biometricType == 'faceID'
        ? Icons.face_rounded
        : Icons.fingerprint_rounded;
    final label = biometricType == 'faceID' ? 'Face ID' : 'Touch ID';

    return _SettingsSection(
      title: 'Security',
      isDark: isDark,
      children: [
        IOSToggleRow(
          icon: icon,
          iconColor: AppColors.accent,
          title: '$label App Lock',
          subtitle: 'Require $label to open the app',
          value: appLockEnabled,
          onChanged: (v) async {
            if (v) {
              // Verify biometrics before enabling
              final auth = await IOSFeaturesService().authenticate(
                reason: 'Enable $label to protect ODC Tracker AI',
              );
              if (auth) {
                ref.read(appLockEnabledProvider.notifier).setEnabled(true);
              }
            } else {
              ref.read(appLockEnabledProvider.notifier).setEnabled(false);
            }
          },
        ),
      ],
    );
  }
}

// ─── Settings Section ─────────────────────────────────────────────────────────
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isDark;

  const _SettingsSection({
    required this.title,
    required this.children,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark ? AppColors.label3Dark : AppColors.label3Light,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ─── About Section ────────────────────────────────────────────────────────────
class _AboutSection extends ConsumerWidget {
  final bool isDark;
  const _AboutSection({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SettingsSection(
      title: 'About',
      isDark: isDark,
      children: [
        IOSListRow(
          leadingIcon: Icons.info_outline_rounded,
          iconColor: isDark ? AppColors.label3Dark : AppColors.label3Light,
          title: 'App Version',
          subtitle: '1.2.0 (Build 12)',
          onTap: null,
        ),
        IOSListRow(
          leadingIcon: Icons.shield_outlined,
          iconColor: isDark ? AppColors.label3Dark : AppColors.label3Light,
          title: 'Privacy Policy',
          onTap: () => IOSFeaturesService.openUrl(
              'https://odctracker.app/privacy'),
        ),
        IOSListRow(
          leadingIcon: Icons.description_outlined,
          iconColor: isDark ? AppColors.label3Dark : AppColors.label3Light,
          title: 'Terms of Service',
          onTap: () => IOSFeaturesService.openUrl(
              'https://odctracker.app/terms'),
          showDivider: false,
        ),
      ],
    );
  }
}

// ─── Sign Out ─────────────────────────────────────────────────────────────────
class _SignOutButton extends ConsumerWidget {
  final bool isDark;
  const _SignOutButton({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IOSListRow(
      leadingIcon: Icons.logout_rounded,
      iconColor: AppColors.danger,
      title: 'Sign Out',
      isDestructive: true,
      showDivider: false,
      onTap: () async {
        final confirm = await showIOSAlert(
          context: context,
          title: 'Sign Out',
          message: 'Are you sure you want to sign out?',
          confirmText: 'Sign Out',
          cancelText: 'Cancel',
          isDestructive: true,
        );
        if (confirm == true && context.mounted) {
          await IOSFeaturesService.warningFeedback();
          await ref.read(authProvider.notifier).signOut();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            );
          }
        }
      },
    );
  }
}
