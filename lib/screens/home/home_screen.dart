import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/attendance_model.dart';
import '../../notifications/notification_service.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider)?.uid;
    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Activate auto shift-end watcher (no-op until endTime is reached)
    ref.watch(autoShiftEndProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todayAttendanceProvider);
            ref.invalidate(activeScheduleProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _HomeHeader(userId: userId)),
              SliverToBoxAdapter(child: _TodayCard(userId: userId)),
              SliverToBoxAdapter(child: _BreakCard(userId: userId)),
              SliverToBoxAdapter(child: _QuickStatsRow()),
              SliverToBoxAdapter(child: _TimelineSection(userId: userId)),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _HomeHeader extends ConsumerWidget {
  final String userId;
  const _HomeHeader({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final firstName = profile?.fullName.split(' ').first ?? '';
    final schedule = ref.watch(activeScheduleProvider).valueOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${DateTimeUtils.getGreeting()}${firstName.isNotEmpty ? ', $firstName' : ''}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.label3Dark : AppColors.label3Light,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 3),
                Text(
                  'ODC Tracker',
                  style: theme.textTheme.headlineLarge,
                ).animate().fadeIn(delay: 80.ms, duration: 400.ms),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  schedule?.displayTime ?? '1 PM – 10 PM',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 4),
              Text(
                DateTimeUtils.formatDateLong(DateTime.now()),
                style: theme.textTheme.labelSmall,
              ).animate().fadeIn(delay: 200.ms),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Today Progress Card ──────────────────────────────────────────────────────
class _TodayCard extends ConsumerWidget {
  final String userId;
  const _TodayCard({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final odcSeconds = ref.watch(currentODCSecondsProvider);
    final breakTime = ref.watch(currentBreakTimeProvider);
    final pct = ref.watch(completionPercentageProvider);
    final remainingODC = ref.watch(remainingODCProvider);
    final isActive = ref.watch(isActiveProvider);
    final isOnBreak = ref.watch(isOnBreakProvider);
    final schedule = ref.watch(activeScheduleProvider).valueOrNull;
    final goalMin = schedule?.requiredOdcMinutes ?? 480;
    final breakLimitMin = schedule?.allowedBreakMinutes ?? 60;

    final clampedPct = pct.clamp(0.0, 100.0);

    // Status color
    final Color statusColor;
    if (!isActive) {
      statusColor = isDark ? AppColors.label3Dark : AppColors.label3Light;
    } else if (isOnBreak) {
      statusColor = AppColors.warning;
    } else {
      statusColor = AppColors.success;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.card(isDark),
        ),
        child: Column(
          children: [
            // ── Ring + main control ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
              child: Row(
                children: [
                  // Circular ring
                  _ODCRing(
                    percentage: clampedPct,
                    odcSeconds: odcSeconds,
                    statusColor: statusColor,
                    isGoalReached: pct >= 100,
                  ),
                  const SizedBox(width: 24),
                  // Info column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(
                          label: 'TODAY',
                          value: '',
                          isHeader: true,
                          statusColor: statusColor,
                          isActive: isActive,
                          isOnBreak: isOnBreak,
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(
                          label: 'Goal',
                          value: DateTimeUtils.formatDuration(goalMin),
                          color: isDark ? AppColors.label3Dark : AppColors.label3Light,
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Remaining',
                          value: DateTimeUtils.formatDuration(remainingODC),
                          color: remainingODC <= 0 ? AppColors.success : (isDark ? AppColors.label2Dark : AppColors.label2Light),
                          bold: remainingODC <= 0,
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Break',
                          value:
                              '${DateTimeUtils.formatDuration(breakTime)} / ${DateTimeUtils.formatDuration(breakLimitMin)}',
                          color: breakTime > breakLimitMin
                              ? AppColors.danger
                              : breakTime > breakLimitMin * 0.8
                                  ? AppColors.warning
                                  : (isDark ? AppColors.label3Dark : AppColors.label3Light),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Separator ───────────────────────────────────────────────
            Divider(
              height: 1,
              color: isDark ? AppColors.separatorDark : AppColors.separatorLight,
              indent: 24,
              endIndent: 24,
            ),

            // ── Action control ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: _ActionControl(userId: userId),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: 100.ms, duration: 500.ms)
          .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),
    );
  }
}

// ─── ODC Ring ─────────────────────────────────────────────────────────────────
class _ODCRing extends StatelessWidget {
  final double percentage;
  final int odcSeconds;
  final Color statusColor;
  final bool isGoalReached;

  const _ODCRing({
    required this.percentage,
    required this.odcSeconds,
    required this.statusColor,
    required this.isGoalReached,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = odcSeconds ~/ 3600;
    final m = (odcSeconds % 3600) ~/ 60;
    final s = odcSeconds % 60;
    final timeStr = h > 0
        ? '$h:${m.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    final timeUnit = h > 0 ? '${m.toString().padLeft(2, '0')}m' : '';

    return SizedBox(
      width: 120,
      height: 120,
      child: CustomPaint(
        painter: _RingPainter(
          progress: percentage / 100,
          color: isGoalReached ? AppColors.success : AppColors.accent,
          trackColor: theme.colorScheme.surfaceContainerHighest,
          strokeWidth: 10,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                h > 0 ? '${h}h $timeUnit' : timeStr,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isGoalReached ? AppColors.success : null,
                  fontSize: h > 0 ? 18 : 22,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isGoalReached ? AppColors.success : AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Info Row ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool bold;
  final bool isHeader;
  final Color? statusColor;
  final bool isActive;
  final bool isOnBreak;

  const _InfoRow({
    required this.label,
    required this.value,
    this.color,
    this.bold = false,
    this.isHeader = false,
    this.statusColor,
    this.isActive = false,
    this.isOnBreak = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (isHeader) {
      final statusText = !isActive
          ? 'Not checked in'
          : isOnBreak
              ? 'On Break'
              : 'Working';
      return Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: theme.textTheme.labelMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall,
        ),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Action Control ───────────────────────────────────────────────────────────
class _ActionControl extends ConsumerStatefulWidget {
  final String userId;
  const _ActionControl({required this.userId});

  @override
  ConsumerState<_ActionControl> createState() => _ActionControlState();
}

class _ActionControlState extends ConsumerState<_ActionControl>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _act(String action) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    // Haptic feedback
    switch (action) {
      case 'checkIn':
        HapticFeedback.mediumImpact();
        break;
      case 'startBreak':
        HapticFeedback.mediumImpact();
        break;
      case 'endBreak':
        HapticFeedback.heavyImpact();
        break;
      case 'checkOut':
        HapticFeedback.lightImpact();
        break;
    }

    try {
      final svc = ref.read(firestoreServiceProvider);
      final notifSvc = NotificationService();
      // Always pass the active schedule so goals/limits are schedule-aware
      final schedule =
          ref.read(activeScheduleProvider).valueOrNull;
      switch (action) {
        case 'checkIn':
          await svc.checkIn(widget.userId, schedule: schedule);
          notifSvc.setUserId(widget.userId);
          notifSvc.stopBreakReminders();
          notifSvc.showCheckInNotification();
          _showSnack('Shift started! 🚀', AppColors.success);
          break;
        case 'startBreak':
          await svc.startBreak(widget.userId, schedule: schedule);
          notifSvc.setUserId(widget.userId);
          notifSvc.startBreakReminders();
          _showSnack('Break started ☕', AppColors.warning);
          break;
        case 'endBreak':
          await svc.endBreak(widget.userId, schedule: schedule);
          notifSvc.stopBreakReminders();
          HapticFeedback.heavyImpact();
          _showSnack('Welcome back! 💪', AppColors.accent);
          break;
        case 'checkOut':
          await svc.checkOut(widget.userId, schedule: schedule);
          notifSvc.stopBreakReminders();
          notifSvc.showCheckOutNotification(
              ref.read(currentODCTimeProvider));
          _showSnack('Shift ended. Great work! ✅', AppColors.success);
          break;
      }
    } catch (e) {
      _showSnack(
          e.toString().replaceAll('Exception: ', ''), AppColors.danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w500)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isActive = ref.watch(isActiveProvider);
    final isOnBreak = ref.watch(isOnBreakProvider);
    final theme = Theme.of(context);

    // Main button config
    final Color btnColor;
    final String btnLabel;
    final String btnAction;
    final IconData btnIcon;

    if (!isActive) {
      btnColor = AppColors.success;
      btnLabel = "I'M IN";
      btnAction = 'checkIn';
      btnIcon = Icons.login_rounded;
    } else if (isOnBreak) {
      btnColor = AppColors.success;
      btnLabel = "I'M IN";
      btnAction = 'endBreak';
      btnIcon = Icons.arrow_back_rounded;
    } else {
      btnColor = AppColors.warning;
      btnLabel = "I'M OUT";
      btnAction = 'startBreak';
      btnIcon = Icons.coffee_rounded;
    }

    return Column(
      children: [
        // ── Main big button ────────────────────────────────────────────
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) {
            final shouldPulse = isActive && !isOnBreak;
            return Transform.scale(
              scale: shouldPulse ? _pulseAnim.value : 1.0,
              child: child,
            );
          },
          child: _isLoading
              ? Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: btnColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: btnColor,
                      ),
                    ),
                  ),
                )
              : _PremiumButton(
                  label: btnLabel,
                  icon: btnIcon,
                  color: btnColor,
                  onTap: () => _act(btnAction),
                ),
        ),

        // ── End Shift secondary ───────────────────────────────────────
        if (isActive && !isOnBreak) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _confirmCheckOut(),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded,
                      color: AppColors.danger, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'End Shift',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmCheckOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('End Shift'),
        content: const Text('Are you sure you want to end your shift?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('End Shift',
                  style: TextStyle(
                      color: AppColors.danger, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirm == true) _act('checkOut');
  }
}

class _PremiumButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PremiumButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _pressAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _pressAnim,
        builder: (context, child) =>
            Transform.scale(scale: _pressAnim.value, child: child),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.color, widget.color.withValues(alpha: 0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.elevated(widget.color),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Break Active Card ────────────────────────────────────────────────────────
class _BreakCard extends ConsumerWidget {
  final String userId;
  const _BreakCard({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnBreak = ref.watch(isOnBreakProvider);
    if (!isOnBreak) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final breakDuration = ref.watch(currentBreakDurationProvider);
    final remainingBreak = ref.watch(remainingBreakProvider);
    final settings = ref.watch(reminderSettingsProvider);
    final nextReminder = ref.watch(nextReminderInProvider);

    final h = breakDuration.inHours;
    final m = breakDuration.inMinutes % 60;
    final s = breakDuration.inSeconds % 60;
    final timeStr = h > 0
        ? '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    final isOverBreak = remainingBreak <= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: (isOverBreak ? AppColors.danger : AppColors.warning)
                .withValues(alpha: 0.4),
          ),
          boxShadow: AppShadows.card(isDark),
        ),
        child: Row(
          children: [
            // Orange circle indicator
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isOverBreak ? AppColors.danger : AppColors.warning)
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOverBreak
                    ? Icons.warning_amber_rounded
                    : Icons.coffee_rounded,
                color: isOverBreak ? AppColors.danger : AppColors.warning,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOverBreak ? 'Break Exceeded!' : 'You are on break',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isOverBreak ? AppColors.danger : AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        timeStr,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontSize: 28,
                          color: isOverBreak ? AppColors.danger : AppColors.warning,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          letterSpacing: -1,
                        ),
                      ),
                      if (!isOverBreak && remainingBreak > 0) ...[
                        const SizedBox(width: 10),
                        Text(
                          '${remainingBreak}m left',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ],
                  ),
                  if (settings.enabled && nextReminder != null)
                    Text(
                      'Next reminder in ${nextReminder.inMinutes}:${(nextReminder.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 300.ms)
          .slideY(begin: -0.06, end: 0),
    );
  }
}

// ─── Quick Stats ──────────────────────────────────────────────────────────────
class _QuickStatsRow extends ConsumerWidget {
  const _QuickStatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final odcTime = ref.watch(currentODCTimeProvider);
    final breakTime = ref.watch(currentBreakTimeProvider);
    final remainingODC = ref.watch(remainingODCProvider);
    final schedule = ref.watch(activeScheduleProvider).valueOrNull;
    final goalMin = schedule?.requiredOdcMinutes ?? 480;
    final breakLimitMin = schedule?.allowedBreakMinutes ?? 60;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatChip(
              label: 'ODC',
              value: DateTimeUtils.formatDuration(odcTime),
              sub: 'of ${DateTimeUtils.formatDuration(goalMin)}',
              color: AppColors.accent,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatChip(
              label: 'Break',
              value: DateTimeUtils.formatDuration(breakTime),
              sub: 'limit ${DateTimeUtils.formatDuration(breakLimitMin)}',
              color: breakTime > breakLimitMin ? AppColors.danger : AppColors.warning,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatChip(
              label: 'Remaining',
              value: remainingODC <= 0 ? 'Done!' : DateTimeUtils.formatDuration(remainingODC),
              sub: remainingODC <= 0 ? '🎉 Goal met' : 'to goal',
              color: remainingODC <= 0 ? AppColors.success : AppColors.accent,
              isDark: isDark,
            ),
          ),
        ],
      )
          .animate()
          .fadeIn(delay: 200.ms, duration: 400.ms),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timeline Section ─────────────────────────────────────────────────────────
class _TimelineSection extends ConsumerWidget {
  final String userId;
  const _TimelineSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final attendanceAsync = ref.watch(todayAttendanceProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 14),
            child: Text(
              "Today's Timeline",
              style: theme.textTheme.titleLarge,
            ),
          ),
          attendanceAsync.when(
            data: (attendance) => attendance == null ||
                    attendance.sessions.isEmpty
                ? _EmptyTimeline(isDark: isDark)
                : _TimelineList(
                    sessions: attendance.sessions, isDark: isDark),
            loading: () => _SkeletonTimeline(isDark: isDark),
            error: (e, _) => _ErrorCard(message: 'Could not load timeline', isDark: isDark),
          ),
        ],
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  final bool isDark;
  const _EmptyTimeline({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.timeline_rounded,
                size: 36,
                color: (isDark ? AppColors.label3Dark : AppColors.label3Light)
                    .withValues(alpha: 0.5)),
            const SizedBox(height: 10),
            Text(
              'No activity yet today',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.label3Dark : AppColors.label3Light,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Tap \"I'M IN\" to start your shift",
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineList extends StatelessWidget {
  final List<SessionModel> sessions;
  final bool isDark;

  const _TimelineList({required this.sessions, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: List.generate(sessions.length, (i) {
          final s = sessions[i];
          final isOdc = s.type == 'odc';
          final color = isOdc ? AppColors.accent : AppColors.warning;
          final isLast = i == sessions.length - 1;
          final dur = s.endTime != null
              ? DateTimeUtils.formatDuration(s.duration)
              : 'Ongoing';

          return Padding(
            padding: EdgeInsets.fromLTRB(16, i == 0 ? 16 : 0, 16, isLast ? 16 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline line + dot
                Column(
                  children: [
                    if (i > 0)
                      Container(width: 1.5, height: 12,
                          color: isDark ? AppColors.separatorDark : AppColors.separatorLight),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isOdc ? Icons.work_rounded : Icons.coffee_rounded,
                        color: color,
                        size: 16,
                      ),
                    ),
                    if (!isLast)
                      Container(width: 1.5, height: 28,
                          color: isDark ? AppColors.separatorDark : AppColors.separatorLight),
                  ],
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOdc
                                  ? (s.endTime == null ? 'Working' : 'ODC Session')
                                  : (s.endTime == null ? 'On Break' : 'Break'),
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateTimeUtils.formatTime12Hour(s.startTime) +
                                  (s.endTime != null
                                      ? ' → ${DateTimeUtils.formatTime12Hour(s.endTime!)}'
                                      : ''),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        Text(
                          dur,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate(delay: Duration(milliseconds: 50 * i))
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.05, end: 0);
        }),
      ),
    );
  }
}

class _SkeletonTimeline extends StatelessWidget {
  final bool isDark;
  const _SkeletonTimeline({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final bool isDark;
  const _ErrorCard({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
