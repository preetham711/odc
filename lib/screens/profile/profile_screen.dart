import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../settings/break_reminder_settings_screen.dart';
import '../settings/profile_edit_screen.dart';
import '../settings/work_schedule_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeMode = ref.watch(themeProvider);
    final userProfile = ref.watch(userProfileProvider);
    final activeSchedule = ref.watch(activeScheduleProvider).valueOrNull;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Large Profile Header ──────────────────────────────────────
          SliverToBoxAdapter(
            child: _ProfileHeader(
              userProfile: userProfile,
              isDark: isDark,
            ).animate().fadeIn(duration: 400.ms),
          ),

          // ── Schedule info ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
            ).animate().fadeIn(delay: 80.ms, duration: 400.ms),
          ),

          SliverToBoxAdapter(child: const SizedBox(height: 20)),

          // ── Settings sections ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _SettingsSection(
                    title: 'Account',
                    isDark: isDark,
                    items: [
                      _SettingItem(
                        icon: Icons.person_rounded,
                        iconColor: AppColors.accent,
                        title: 'Edit Profile',
                        subtitle: 'Name, Employee ID',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileEditScreen()),
                        ).then((_) => ref.invalidate(userProfileProvider)),
                      ),
                      _SettingItem(
                        icon: Icons.schedule_rounded,
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

                  _SettingsSection(
                    title: 'Notifications',
                    isDark: isDark,
                    items: [
                      _SettingItem(
                        icon: Icons.notifications_active_rounded,
                        iconColor: AppColors.warning,
                        title: 'Break Reminders',
                        subtitle: 'Configure return reminders',
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

                  _SettingsSection(
                    title: 'Appearance',
                    isDark: isDark,
                    items: [
                      _ThemeSelector(themeMode: themeMode, isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _SettingsSection(
                    title: 'About',
                    isDark: isDark,
                    items: [
                      _SettingItem(
                        icon: Icons.info_outline_rounded,
                        iconColor: isDark
                            ? AppColors.label3Dark
                            : AppColors.label3Light,
                        title: 'App Version',
                        subtitle: '1.0.0',
                        onTap: null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sign out
                  _SignOutButton(isDark: isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
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
    final user = userProfile.when(
      data: (u) => u,
      loading: () => null,
      error: (_, __) => null,
    );

    final name = user?.fullName ?? '';
    final mobile = user?.mobileNumber ?? '';
    final employeeId = user?.employeeId;
    final initials = name.isNotEmpty
        ? name
            .split(' ')
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join()
        : '?';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
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
          // Avatar
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
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
          const SizedBox(height: 16),
          Text(
            name.isNotEmpty ? name : 'Loading...',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          if (mobile.isNotEmpty)
            Text(mobile, style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.label3Dark : AppColors.label3Light,
            )),
          if (employeeId != null && employeeId.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
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
    final displayTime = schedule?.displayTime ?? '1 PM – 10 PM';
    final name = schedule?.name ?? 'Default Schedule';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.schedule_rounded,
                  color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      )),
                  Text(displayTime, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: isDark ? AppColors.label3Dark : AppColors.label3Light),
          ],
        ),
      ),
    );
  }
}

// ─── Settings Section ─────────────────────────────────────────────────────────
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  final bool isDark;

  const _SettingsSection({
    required this.title,
    required this.items,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
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
          child: Column(
            children: List.generate(items.length, (i) {
              return Column(
                children: [
                  items[i],
                  if (i < items.length - 1)
                    Divider(
                      height: 1,
                      indent: 56,
                      color: isDark
                          ? AppColors.separatorDark
                          : AppColors.separatorLight,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ─── Setting Item ─────────────────────────────────────────────────────────────
class _SettingItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Theme Selector ───────────────────────────────────────────────────────────
class _ThemeSelector extends ConsumerWidget {
  final ThemeMode themeMode;
  final bool isDark;

  const _ThemeSelector({required this.themeMode, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.palette_rounded,
                size: 18, color: AppColors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text('Appearance', style: theme.textTheme.titleSmall),
          ),
          // Segmented control
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ThemeOption(
                  icon: Icons.light_mode_rounded,
                  label: 'Light',
                  mode: ThemeMode.light,
                  current: themeMode,
                  isDark: isDark,
                ),
                _ThemeOption(
                  icon: Icons.dark_mode_rounded,
                  label: 'Dark',
                  mode: ThemeMode.dark,
                  current: themeMode,
                  isDark: isDark,
                ),
                _ThemeOption(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Auto',
                  mode: ThemeMode.system,
                  current: themeMode,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends ConsumerWidget {
  final IconData icon;
  final String label;
  final ThemeMode mode;
  final ThemeMode current;
  final bool isDark;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.mode,
    required this.current,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = current == mode;
    return GestureDetector(
      onTap: () => ref.read(themeProvider.notifier).setTheme(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected
                    ? AppColors.accent
                    : (isDark ? AppColors.label3Dark : AppColors.label3Light)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? AppColors.accent
                    : (isDark ? AppColors.label3Dark : AppColors.label3Light),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sign Out ─────────────────────────────────────────────────────────────────
class _SignOutButton extends ConsumerWidget {
  final bool isDark;
  const _SignOutButton({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Sign Out',
                      style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600))),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
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
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
            const SizedBox(width: 10),
            Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
