import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'break_reminder_settings_screen.dart';
import 'profile_edit_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Profile card
          userProfile.when(
            data: (user) => user == null
                ? const SizedBox.shrink()
                : GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfileEditScreen()),
                    ).then((_) => ref.invalidate(userProfileProvider)),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppTheme.primaryBlue,
                            child: Text(
                              user.fullName.isNotEmpty
                                  ? user.fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.fullName,
                                    style: theme.textTheme.titleLarge),
                                const SizedBox(height: 2),
                                Text(user.mobileNumber,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    )),
                                if (user.employeeId != null) ...[
                                  const SizedBox(height: 2),
                                  Text('ID: ${user.employeeId}',
                                      style: theme.textTheme.bodySmall),
                                ],
                              ],
                            ),
                          ),
                          Icon(Icons.edit_rounded,
                              color: AppTheme.primaryBlue.withValues(alpha: 0.6),
                              size: 18),
                        ],
                      ),
                    ),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),

          _buildSection(context, 'Appearance', [
            _buildThemeSelector(context, ref, themeMode),
          ]),
          const SizedBox(height: 24),

          _buildSection(context, 'Profile', [
            _buildSettingTile(
                context,
                'Edit Profile',
                'Name, Employee ID, shift timing',
                Icons.person_rounded,
                () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfileEditScreen()),
                    ).then((_) => ref.invalidate(userProfileProvider))),
          ]),
          const SizedBox(height: 24),

          _buildSection(context, 'Notifications', [
            _buildSettingTile(
                context,
                'Break Reminder',
                'Configure return reminders while on break',
                Icons.notifications_active_rounded,
                () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const BreakReminderSettingsScreen()),
                    )),
          ]),
          const SizedBox(height: 24),

          _buildSection(context, 'Shift Configuration', [
            userProfile.when(
              data: (user) => _buildSettingTile(
                  context,
                  'Shift Timing',
                  user != null
                      ? '${_fmt12h(user.shiftStart)} – ${_fmt12h(user.shiftEnd)}'
                      : '1:00 PM – 10:00 PM',
                  Icons.access_time_rounded,
                  () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileEditScreen()),
                      ).then((_) => ref.invalidate(userProfileProvider))),
              loading: () => _buildSettingTile(context, 'Shift Timing',
                  '1:00 PM – 10:00 PM', Icons.access_time_rounded, null),
              error: (_, __) => _buildSettingTile(context, 'Shift Timing',
                  '1:00 PM – 10:00 PM', Icons.access_time_rounded, null),
            ),
            userProfile.when(
              data: (user) => _buildSettingTile(
                  context,
                  'Daily Goal',
                  user != null ? '${user.dailyGoal ~/ 60}h ${user.dailyGoal % 60 > 0 ? '${user.dailyGoal % 60}m' : ''}'.trim() : '8 hours',
                  Icons.flag_rounded,
                  null),
              loading: () => _buildSettingTile(
                  context, 'Daily Goal', '8 hours', Icons.flag_rounded, null),
              error: (_, __) => _buildSettingTile(
                  context, 'Daily Goal', '8 hours', Icons.flag_rounded, null),
            ),
            userProfile.when(
              data: (user) => _buildSettingTile(
                  context,
                  'Break Limit',
                  user != null ? '${user.breakLimit} min max' : '1 hour max',
                  Icons.coffee_rounded,
                  null),
              loading: () => _buildSettingTile(context, 'Break Limit',
                  '1 hour max', Icons.coffee_rounded, null),
              error: (_, __) => _buildSettingTile(context, 'Break Limit',
                  '1 hour max', Icons.coffee_rounded, null),
            ),
          ]),
          const SizedBox(height: 24),

          _buildSection(context, 'About', [
            _buildSettingTile(
                context, 'App Version', '1.0.0', Icons.info_rounded, null),
          ]),
          const SizedBox(height: 24),

          // Logout
          Material(
            color: Colors.transparent,
            child: InkWell(
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
                          child: const Text('Sign Out',
                              style: TextStyle(color: AppTheme.dangerRed))),
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
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.dangerRed.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded,
                        color: AppTheme.dangerRed),
                    const SizedBox(width: 12),
                    Text(
                      'Sign Out',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.dangerRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingTile(BuildContext context, String title, String subtitle,
      IconData icon, VoidCallback? onTap) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryBlue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }

  /// Convert "HH:mm" 24h string to "H:MM AM/PM"
  String _fmt12h(String hhmm) {
    try {
      final parts = hhmm.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final period = h < 12 ? 'AM' : 'PM';
      final h12 = h % 12 == 0 ? 12 : h % 12;
      return '$h12:${m.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return hhmm;
    }
  }

  Widget _buildThemeSelector(
      BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.palette_rounded,
                    color: AppTheme.primaryBlue),
              ),
              const SizedBox(width: 16),
              Text('Theme', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _themeOption(context, ref, 'Light',
                      Icons.light_mode_rounded, ThemeMode.light, currentMode)),
              const SizedBox(width: 12),
              Expanded(
                  child: _themeOption(context, ref, 'Dark',
                      Icons.dark_mode_rounded, ThemeMode.dark, currentMode)),
              const SizedBox(width: 12),
              Expanded(
                  child: _themeOption(
                      context,
                      ref,
                      'System',
                      Icons.auto_awesome_rounded,
                      ThemeMode.system,
                      currentMode)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _themeOption(BuildContext context, WidgetRef ref, String label,
      IconData icon, ThemeMode mode, ThemeMode current) {
    final theme = Theme.of(context);
    final selected = current == mode;
    return GestureDetector(
      onTap: () => ref.read(themeProvider.notifier).setTheme(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primaryBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected
                    ? AppTheme.primaryBlue
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: selected
                    ? AppTheme.primaryBlue
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
