import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../models/attendance_model.dart';
import '../../utils/date_utils.dart';
import '../../theme/app_theme.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final _todayReportProvider = FutureProvider<AttendanceModel?>((ref) async {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return null;
  return ref.read(firestoreServiceProvider).getTodayAttendance(uid);
});

final _weeklyAttendanceProvider =
    FutureProvider<List<AttendanceModel>>((ref) async {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return [];
  final now = DateTime.now();
  final start = now.subtract(Duration(days: now.weekday - 1));
  return ref.read(firestoreServiceProvider).getAttendanceByDateRange(
      uid,
      DateTime(start.year, start.month, start.day),
      DateTime(now.year, now.month, now.day));
});

final _monthlyAttendanceProvider =
    FutureProvider<List<AttendanceModel>>((ref) async {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return [];
  final now = DateTime.now();
  return ref.read(firestoreServiceProvider).getAttendanceByDateRange(
      uid,
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 0));
});

final _yearlyAttendanceProvider =
    FutureProvider<List<AttendanceModel>>((ref) async {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return [];
  final now = DateTime.now();
  return ref.read(firestoreServiceProvider).getAttendanceByDateRange(
      uid, DateTime(now.year, 1, 1), DateTime(now.year, 12, 31));
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reports',
                      style: theme.textTheme.headlineLarge),
                  const SizedBox(height: 4),
                  Text('Your attendance analytics',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.label3Dark
                            : AppColors.label3Light,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.surface2Dark : AppColors.surface2Light,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color:
                      isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: AppShadows.card(isDark),
                ),
                labelColor: AppColors.accent,
                unselectedLabelColor:
                    isDark ? AppColors.label3Dark : AppColors.label3Light,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
                tabs: const [
                  Tab(text: 'Daily'),
                  Tab(text: 'Weekly'),
                  Tab(text: 'Monthly'),
                  Tab(text: 'Yearly'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _DailyReport(),
                  _RangeReport(range: _Range.weekly),
                  _RangeReport(range: _Range.monthly),
                  _RangeReport(range: _Range.yearly),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Daily ────────────────────────────────────────────────────────────────────

class _DailyReport extends ConsumerWidget {
  const _DailyReport();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final attAsync = ref.watch(_todayReportProvider);
    final scheduleAsync = ref.watch(activeScheduleProvider);

    return attAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorCard(message: 'Could not load today\'s report'),
      data: (att) {
        final goalMin =
            scheduleAsync.valueOrNull?.requiredOdcMinutes ?? 480;

        if (att == null) {
          return _EmptyState(
            icon: Icons.today_rounded,
            title: 'No attendance today',
            subtitle: 'Check in from the Today tab to start tracking.',
          );
        }

        final odcMin = att.odcTime;
        final breakMin = att.breakTime;
        final pct = (odcMin / goalMin * 100).clamp(0.0, 100.0);
        final breaks =
            att.sessions.where((s) => s.type == 'break').length;
        final extraMin = (odcMin - goalMin).clamp(0, 9999);
        final missingMin = (goalMin - odcMin).clamp(0, 9999);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date + schedule
              _SectionHeader(
                title: DateTimeUtils.formatDateLong(att.date),
                subtitle: scheduleAsync.valueOrNull?.displayTime ?? '',
              ),
              const SizedBox(height: 16),

              // Completion ring card
              _CompletionCard(
                odcMin: odcMin,
                goalMin: goalMin,
                pct: pct,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Stats grid
              _StatsGrid(items: [
                _StatItem('ODC Time', DateTimeUtils.formatDuration(odcMin),
                    AppColors.accent),
                _StatItem('Break Time',
                    DateTimeUtils.formatDuration(breakMin), AppColors.warning),
                _StatItem('Goal',
                    DateTimeUtils.formatDuration(goalMin), AppColors.success),
                _StatItem('Breaks Taken', '$breaks', AppColors.warning),
                if (extraMin > 0)
                  _StatItem('Extra Time',
                      DateTimeUtils.formatDuration(extraMin), AppColors.success),
                if (missingMin > 0)
                  _StatItem('Missing Time',
                      DateTimeUtils.formatDuration(missingMin), AppColors.danger),
              ]),
              const SizedBox(height: 20),

              // Check-in/out times
              if (att.checkIn != null || att.checkOut != null)
                _CheckInOutRow(att: att),
              const SizedBox(height: 20),

              // Timeline
              _SessionTimeline(sessions: att.sessions, isDark: isDark),
            ],
          ),
        );
      },
    );
  }
}

// ─── Range Report ─────────────────────────────────────────────────────────────

enum _Range { weekly, monthly, yearly }

class _RangeReport extends ConsumerWidget {
  final _Range range;
  const _RangeReport({required this.range});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final AsyncValue<List<AttendanceModel>> attAsync;
    switch (range) {
      case _Range.weekly:
        attAsync = ref.watch(_weeklyAttendanceProvider);
        break;
      case _Range.monthly:
        attAsync = ref.watch(_monthlyAttendanceProvider);
        break;
      case _Range.yearly:
        attAsync = ref.watch(_yearlyAttendanceProvider);
        break;
    }

    return attAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorCard(message: 'Could not load report: $e'),
      data: (list) {
        if (list.isEmpty) {
          return _EmptyState(
            icon: Icons.bar_chart_rounded,
            title: 'No data yet',
            subtitle: 'Records will appear here once you start tracking.',
          );
        }

        final stats = _calcStats(list);
        final title = range == _Range.weekly
            ? 'This Week'
            : range == _Range.monthly
                ? 'This Month'
                : 'This Year';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: title,
                subtitle: '${list.length} day${list.length == 1 ? '' : 's'} recorded',
              ),
              const SizedBox(height: 16),

              // Summary stats
              _StatsGrid(items: [
                _StatItem('Total ODC',
                    DateTimeUtils.formatDuration(stats.totalODC), AppColors.accent),
                _StatItem('Total Break',
                    DateTimeUtils.formatDuration(stats.totalBreak), AppColors.warning),
                _StatItem('Avg ODC/Day',
                    DateTimeUtils.formatDuration(stats.avgODC), AppColors.accent),
                _StatItem('Perfect Days',
                    '${stats.perfectDays}', AppColors.success),
                _StatItem('Missed Days',
                    '${stats.missedDays}', AppColors.danger),
                if (stats.extraODC > 0)
                  _StatItem('Extra Time',
                      DateTimeUtils.formatDuration(stats.extraODC), AppColors.success),
              ]),
              const SizedBox(height: 20),

              // Bar chart
              _BarChart(records: list, isDark: isDark),
            ],
          ),
        );
      },
    );
  }

  _RangeStats _calcStats(List<AttendanceModel> list) {
    int totalODC = 0, totalBreak = 0, perfectDays = 0, missedDays = 0,
        extraODC = 0;
    for (final a in list) {
      totalODC += a.odcTime;
      totalBreak += a.breakTime;
      if (a.completionPercentage >= 100) {
        perfectDays++;
        extraODC += a.odcTime - (480 - a.remainingODC);
      } else if (a.odcTime == 0) {
        missedDays++;
      }
    }
    return _RangeStats(
      totalODC: totalODC,
      totalBreak: totalBreak,
      avgODC: list.isEmpty ? 0 : totalODC ~/ list.length,
      perfectDays: perfectDays,
      missedDays: missedDays,
      extraODC: extraODC.clamp(0, 99999),
    );
  }
}

class _RangeStats {
  final int totalODC, totalBreak, avgODC, perfectDays, missedDays, extraODC;
  const _RangeStats({
    required this.totalODC,
    required this.totalBreak,
    required this.avgODC,
    required this.perfectDays,
    required this.missedDays,
    required this.extraODC,
  });
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, this.subtitle = ''});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineSmall),
        if (subtitle.isNotEmpty)
          Text(subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              )),
      ],
    );
  }
}

class _CompletionCard extends StatelessWidget {
  final int odcMin, goalMin;
  final double pct;
  final bool isDark;
  const _CompletionCard({
    required this.odcMin,
    required this.goalMin,
    required this.pct,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = pct >= 100
        ? AppColors.success
        : pct >= 50
            ? AppColors.accent
            : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card(isDark),
      ),
      child: Row(
        children: [
          // Ring
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: pct / 100,
                  strokeWidth: 8,
                  backgroundColor: isDark
                      ? AppColors.surface2Dark
                      : AppColors.surface2Light,
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pct >= 100 ? '🎉 Goal Achieved!' : 'In Progress',
                  style: theme.textTheme.titleMedium?.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateTimeUtils.formatDuration(odcMin)} of ${DateTimeUtils.formatDuration(goalMin)}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                if (pct < 100)
                  Text(
                    '${DateTimeUtils.formatDuration((goalMin - odcMin).clamp(0, goalMin))} remaining',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.label3Dark : AppColors.label3Light,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _StatsGrid extends StatelessWidget {
  final List<_StatItem> items;
  const _StatsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _StatCard(item: items[i]),
    );
  }
}

class _StatItem {
  final String label, value;
  final Color color;
  const _StatItem(this.label, this.value, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: item.color,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 4),
          Text(item.value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: item.color,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}

class _CheckInOutRow extends StatelessWidget {
  final AttendanceModel att;
  const _CheckInOutRow({required this.att});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      children: [
        if (att.checkIn != null)
          Expanded(
            child: _TimeChipCard(
              icon: Icons.login_rounded,
              label: 'Check In',
              time: DateTimeUtils.formatTime12Hour(att.checkIn!),
              color: AppColors.success,
              isDark: isDark,
            ),
          ),
        if (att.checkIn != null && att.checkOut != null)
          const SizedBox(width: 10),
        if (att.checkOut != null)
          Expanded(
            child: _TimeChipCard(
              icon: Icons.logout_rounded,
              label: 'Check Out',
              time: DateTimeUtils.formatTime12Hour(att.checkOut!),
              color: AppColors.danger,
              isDark: isDark,
            ),
          ),
      ],
    );
  }
}

class _TimeChipCard extends StatelessWidget {
  final IconData icon;
  final String label, time;
  final Color color;
  final bool isDark;
  const _TimeChipCard({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(color: color)),
          Text(time,
              style: theme.textTheme.titleMedium?.copyWith(
                  color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SessionTimeline extends StatelessWidget {
  final List<SessionModel> sessions;
  final bool isDark;
  const _SessionTimeline(
      {required this.sessions, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (sessions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Session Timeline", style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Container(
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
                padding: EdgeInsets.fromLTRB(
                    16, i == 0 ? 14 : 0, 16, isLast ? 14 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        if (i > 0)
                          Container(
                              width: 1.5,
                              height: 10,
                              color: isDark
                                  ? AppColors.separatorDark
                                  : AppColors.separatorLight),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isOdc
                                ? Icons.work_rounded
                                : Icons.coffee_rounded,
                            color: color,
                            size: 15,
                          ),
                        ),
                        if (!isLast)
                          Container(
                              width: 1.5,
                              height: 24,
                              color: isDark
                                  ? AppColors.separatorDark
                                  : AppColors.separatorLight),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isOdc
                                      ? (s.endTime == null
                                          ? 'Working'
                                          : 'ODC Session')
                                      : (s.endTime == null
                                          ? 'On Break'
                                          : 'Break'),
                                  style:
                                      theme.textTheme.titleSmall?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  DateTimeUtils.formatTime12Hour(
                                          s.startTime) +
                                      (s.endTime != null
                                          ? ' → ${DateTimeUtils.formatTime12Hour(s.endTime!)}'
                                          : ''),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            Text(dur,
                                style: theme.textTheme.labelMedium
                                    ?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<AttendanceModel> records;
  final bool isDark;
  const _BarChart({required this.records, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Show up to 7 most recent days / months
    final data = records.take(7).toList().reversed.toList();
    if (data.isEmpty) return const SizedBox.shrink();

    final maxY = data
            .map((a) => a.odcTime.toDouble())
            .reduce((a, b) => a > b ? a : b)
            .clamp(60.0, double.infinity) *
        1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ODC Time Chart', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => isDark
                      ? AppColors.surface3Dark
                      : AppColors.surface3Light,
                  getTooltipItem: (g, gi, rod, ri) => BarTooltipItem(
                    DateTimeUtils.formatDuration(rod.toY.toInt()),
                    TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      if (i < 0 || i >= data.length) {
                        return const Text('');
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${data[i].date.day}/${data[i].date.month}',
                          style: theme.textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: isDark
                      ? AppColors.separatorDark
                      : AppColors.separatorLight,
                  strokeWidth: 0.5,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(data.length, (i) {
                final pct = data[i].completionPercentage;
                final color = pct >= 100
                    ? AppColors.success
                    : pct >= 50
                        ? AppColors.accent
                        : AppColors.warning;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: data[i].odcTime.toDouble(),
                      color: color,
                      width: 22,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
      ],
    );
  }
}

// ─── Empty state / Error ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 48,
                color: (isDark ? AppColors.label3Dark : AppColors.label3Light)
                    .withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.label3Dark : AppColors.label3Light,
                ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.danger),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.danger),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
