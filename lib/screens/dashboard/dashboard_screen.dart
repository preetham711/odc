import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../notifications/notification_service.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../utils/date_utils.dart';
import '../../widgets/circular_progress_indicator.dart';
import '../../widgets/action_button.dart';
import '../../widgets/stat_card.dart';
import '../../theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider)?.uid;
    final userProfile = ref.watch(userProfileProvider);
    final attendanceAsync = ref.watch(todayAttendanceProvider);
    final odcTime = ref.watch(currentODCTimeProvider);
    final breakTime = ref.watch(currentBreakTimeProvider);
    final completionPercentage = ref.watch(completionPercentageProvider);
    final remainingODC = ref.watch(remainingODCProvider);
    final remainingBreak = ref.watch(remainingBreakProvider);
    final isActive = ref.watch(isActiveProvider);
    final isOnBreak = ref.watch(isOnBreakProvider);

    if (userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Extract first name
    final firstName = userProfile.when(
      data: (u) => u?.fullName.split(' ').first ?? '',
      loading: () => '',
      error: (_, __) => '',
    );

    return Scaffold(
      body: SafeArea(
        child: attendanceAsync.when(
          data: (attendance) => _DashboardBody(
            userId: userId,
            firstName: firstName,
            attendance: attendance,
            odcTime: odcTime,
            breakTime: breakTime,
            completionPercentage: completionPercentage,
            remainingODC: remainingODC,
            remainingBreak: remainingBreak,
            isActive: isActive,
            isOnBreak: isOnBreak,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 48, color: AppTheme.dangerRed),
                  const SizedBox(height: 12),
                  Text('$error', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        ref.refresh(todayAttendanceProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  final String userId;
  final String firstName;
  final dynamic attendance;
  final int odcTime;
  final int breakTime;
  final double completionPercentage;
  final int remainingODC;
  final int remainingBreak;
  final bool isActive;
  final bool isOnBreak;

  const _DashboardBody({
    required this.userId,
    required this.firstName,
    required this.attendance,
    required this.odcTime,
    required this.breakTime,
    required this.completionPercentage,
    required this.remainingODC,
    required this.remainingBreak,
    required this.isActive,
    required this.isOnBreak,
  });

  /// Convert "HH:mm" → "H AM/PM"
  String _fmt12h(String hhmm) {
    try {
      final parts = hhmm.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final period = h < 12 ? 'AM' : 'PM';
      final h12 = h % 12 == 0 ? 12 : h % 12;
      return m == 0 ? '$h12 $period' : '$h12:${m.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return hhmm;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          _buildHeader(theme, ref),
          const SizedBox(height: 28),

          // ── Circular Progress ────────────────────────────────────────
          _buildCircularProgress(theme, ref),
          const SizedBox(height: 24),

          // ── Status badge ─────────────────────────────────────────────
          _buildStatusBadge(theme),
          const SizedBox(height: 16),

          // ── Live Break Panel (only when on break) ─────────────────────
          if (isOnBreak) const _LiveBreakPanel(),
          if (!isOnBreak) const SizedBox(height: 8),
          const SizedBox(height: 8),

          // ── Quick Stats ──────────────────────────────────────────────
          _buildQuickStats(theme),
          const SizedBox(height: 24),

          // ── Action Buttons ───────────────────────────────────────────
          _buildActionButtons(context, ref),
          const SizedBox(height: 28),

          // ── Today's Overview ─────────────────────────────────────────
          Text("Today's Overview",
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: 14),
          Builder(builder: (context) {
            final profile = ref.watch(userProfileProvider).valueOrNull;
            final goalLabel = profile != null ? '${profile.dailyGoal ~/ 60}h goal' : '8h goal';
            final breakLabel = profile != null ? '${profile.breakLimit}m max' : '1h max';
            return Row(children: [
              Expanded(
                  child: StatCard(
                      title: 'Total ODC',
                      value: DateTimeUtils.formatDuration(odcTime),
                      icon: Icons.work_outline_rounded,
                      color: AppTheme.primaryBlue,
                      subtitle: goalLabel)),
              const SizedBox(width: 16),
              Expanded(
                  child: StatCard(
                      title: 'Total Break',
                      value: DateTimeUtils.formatDuration(breakTime),
                      icon: Icons.coffee_outlined,
                      color: AppTheme.warningOrange,
                      subtitle: breakLabel)),
            ]);
          }),
          const SizedBox(height: 28),

          // ── Timeline ─────────────────────────────────────────────────
          Text("Today's Timeline",
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: 14),
          _buildTimeline(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final shiftLabel = profile != null
        ? '${_fmt12h(profile.shiftStart)} – ${_fmt12h(profile.shiftEnd)}'
        : '1 PM – 10 PM';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${DateTimeUtils.getGreeting()}${firstName.isNotEmpty ? ', $firstName' : ''}! 👋',
                style: theme.textTheme.displaySmall,
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
              const SizedBox(height: 4),
              Text(
                DateTimeUtils.formatDateLong(DateTime.now()),
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.6)),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            shiftLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
      ],
    );
  }

  Widget _buildCircularProgress(ThemeData theme, WidgetRef ref) {
    return Center(
      child: AnimatedCircularProgress(
        percentage: completionPercentage.clamp(0, 100),
        size: 230,
        strokeWidth: 16,
        progressColor: completionPercentage >= 100
            ? AppTheme.successGreen
            : AppTheme.primaryBlue,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateTimeUtils.formatDuration(odcTime),
              style: theme.textTheme.displayMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'ODC Time',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 8),
            Text(
              '${completionPercentage.toStringAsFixed(1)}%',
              style: theme.textTheme.titleLarge?.copyWith(
                  color: completionPercentage >= 100
                      ? AppTheme.successGreen
                      : AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.easeOut);
  }

  Widget _buildStatusBadge(ThemeData theme) {
    final Color color;
    final IconData icon;
    final String label;

    if (!isActive) {
      color = theme.colorScheme.onSurface.withValues(alpha: 0.4);
      icon = Icons.radio_button_off_rounded;
      label = 'Not checked in';
    } else if (isOnBreak) {
      color = AppTheme.warningOrange;
      icon = Icons.coffee_rounded;
      label = 'On Break';
    } else {
      color = AppTheme.successGreen;
      icon = Icons.radio_button_checked_rounded;
      label = 'Working';
    }

    return Center(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme) {
    return Row(children: [
      Expanded(
          child: QuickStatCard(
              label: 'Remaining ODC',
              value: DateTimeUtils.formatDuration(remainingODC),
              icon: Icons.timer_outlined,
              color: AppTheme.primaryBlue)),
      const SizedBox(width: 14),
      Expanded(
          child: QuickStatCard(
              label: 'Remaining Break',
              value: DateTimeUtils.formatDuration(remainingBreak),
              icon: Icons.free_breakfast_outlined,
              color: AppTheme.warningOrange)),
    ]).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {

    Future<void> act(String action) async {
      try {
        final svc = ref.read(firestoreServiceProvider);
        final notifSvc = NotificationService();
        switch (action) {
          case 'checkIn':
            await svc.checkIn(userId);
            notifSvc.setUserId(userId);
            notifSvc.stopBreakReminders();
            notifSvc.showCheckInNotification();
            if (context.mounted) {
              _snack(context, 'Checked in! Have a productive shift 🚀',
                  AppTheme.successGreen);
            }
            break;
          case 'startBreak':
            await svc.startBreak(userId);
            notifSvc.setUserId(userId);
            notifSvc.startBreakReminders();
            if (context.mounted) {
              _snack(context, 'Break started ☕', AppTheme.warningOrange);
            }
            break;
          case 'endBreak':
            await svc.endBreak(userId);
            notifSvc.stopBreakReminders();
            if (context.mounted) {
              _snack(context, 'Back to work 💪', AppTheme.primaryBlue);
            }
            break;
          case 'checkOut':
            await svc.checkOut(userId);
            notifSvc.stopBreakReminders();
            notifSvc.showCheckOutNotification(ref.read(currentODCTimeProvider));
            if (context.mounted) {
              _snack(context, 'Shift ended. Great work! ✅',
                  AppTheme.successGreen);
            }
            break;
        }
      } catch (e) {
        if (context.mounted) {
          _snack(context, e.toString().replaceAll('Exception: ', ''),
              AppTheme.dangerRed);
        }
      }
    }

    return Column(
      children: [
        // Primary button changes based on state
        PremiumActionButton(
          // Green (isActive=false) when not checked in OR when on break (show "END BREAK" in green)
          // Red (isActive=true) when working (show "START BREAK" or "I'M OUT")
          isActive: isActive && !isOnBreak,
          activeText: "START BREAK",
          inactiveText: isOnBreak ? 'END BREAK ☕' : "I'M IN",
          onPressed: () {
            if (!isActive) {
              act('checkIn');
            } else if (isOnBreak) {
              act('endBreak');
            } else {
              act('startBreak');
            }
          },
        ),
        // End shift button — only when active and not on break
        if (isActive && !isOnBreak) ...[
          const SizedBox(height: 14),
          SecondaryActionButton(
            text: 'End Shift',
            icon: Icons.logout_rounded,
            color: AppTheme.dangerRed,
            onPressed: () => act('checkOut'),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeline(ThemeData theme) {
    if (attendance == null || attendance.sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.timeline_rounded,
                  size: 40,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.3)),
              const SizedBox(height: 10),
              Text('No activity yet today',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5))),
              const SizedBox(height: 4),
              Text('Tap "I\'M IN" to start your shift',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.4))),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: List.generate(attendance.sessions.length, (i) {
          final s = attendance.sessions[i];
          final isOdc = s.type == 'odc';
          final color =
              isOdc ? AppTheme.primaryBlue : AppTheme.warningOrange;
          final isLast = i == attendance.sessions.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                        isOdc
                            ? Icons.work_outline_rounded
                            : Icons.coffee_outlined,
                        color: color,
                        size: 18),
                  ),
                  if (!isLast)
                    Container(
                        width: 2,
                        height: 36,
                        color:
                            color.withValues(alpha: 0.2)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: isLast ? 0 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isOdc
                                ? (s.endTime == null
                                    ? '🟢 Working'
                                    : 'ODC Session')
                                : (s.endTime == null
                                    ? '☕ On Break'
                                    : 'Break'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: color),
                          ),
                          Text(
                            DateTimeUtils.formatTime12Hour(s.startTime),
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                      if (s.endTime != null)
                        Text(
                          DateTimeUtils.formatDuration(s.duration),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: color),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  void _snack(BuildContext ctx, String msg, Color color) {
    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

// ── Live Break Panel ────────────────────────────────────────────────────────
/// Shown on the dashboard while the user is OUT / on break.
class _LiveBreakPanel extends ConsumerWidget {
  const _LiveBreakPanel();

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final breakElapsed = ref.watch(breakElapsedProvider);
    final nextReminder = ref.watch(nextReminderInProvider);
    final settings = ref.watch(reminderSettingsProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.warningOrange.withValues(alpha: 0.15),
            AppTheme.warningOrange.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.warningOrange.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.coffee_rounded,
                    color: AppTheme.warningOrange, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                '🔴 Outside ODC',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.warningOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Break timer row
          Row(
            children: [
              Expanded(
                child: _LiveStatItem(
                  label: 'Break Time',
                  value: _fmt(breakElapsed),
                  icon: Icons.timer_rounded,
                  color: AppTheme.warningOrange,
                  isLarge: true,
                ),
              ),
              const SizedBox(width: 12),
              if (settings.enabled && nextReminder != null)
                Expanded(
                  child: _LiveStatItem(
                    label: 'Next Reminder',
                    value: _fmt(nextReminder),
                    icon: Icons.notifications_active_rounded,
                    color: AppTheme.primaryBlue,
                    isLarge: false,
                  ),
                ),
            ],
          ),

          // Interval chip
          if (settings.enabled) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.alarm_rounded,
                      color: AppTheme.primaryBlue, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Reminders every ${settings.intervalMinutes} min',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Reminders are disabled',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }
}

class _LiveStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isLarge;

  const _LiveStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isLarge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color.withValues(alpha: 0.7), size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: (isLarge
                  ? theme.textTheme.headlineSmall
                  : theme.textTheme.titleLarge)
              ?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
