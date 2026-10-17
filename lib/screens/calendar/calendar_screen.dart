import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/attendance_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';

final _calendarAttendanceProvider =
    FutureProvider<List<AttendanceModel>>((ref) async {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return [];
  final now = DateTime.now();
  // Load current month ± 1
  final start = DateTime(now.year, now.month - 1, 1);
  final end = DateTime(now.year, now.month + 2, 0);
  return ref
      .read(firestoreServiceProvider)
      .getAttendanceByDateRange(uid, start, end);
});

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attAsync = ref.watch(_calendarAttendanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: attAsync.when(
        data: (records) {
          // Build a map: date → attendance
          final map = <DateTime, AttendanceModel>{};
          for (final r in records) {
            map[DateTimeUtils.startOfDay(r.date)] = r;
          }

          final selectedAtt =
              map[DateTimeUtils.startOfDay(_selectedDay)];

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (d) =>
                    isSameDay(_selectedDay, d),
                onDaySelected: (sel, foc) {
                  setState(() {
                    _selectedDay = sel;
                    _focusedDay = foc;
                  });
                },
                onPageChanged: (foc) =>
                    setState(() => _focusedDay = foc),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    final att =
                        map[DateTimeUtils.startOfDay(day)];
                    if (att == null) return null;
                    final color = att.completionPercentage >= 100
                        ? AppTheme.successGreen
                        : att.completionPercentage > 0
                            ? AppTheme.warningOrange
                            : AppTheme.dangerRed;
                    return Positioned(
                      bottom: 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle),
                      ),
                    );
                  },
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: selectedAtt == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 48,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            Text(
                              'No attendance on ${DateTimeUtils.formatDate(_selectedDay)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child:
                            _AttendanceDetail(attendance: selectedAtt),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _AttendanceDetail extends StatelessWidget {
  final AttendanceModel attendance;
  const _AttendanceDetail({required this.attendance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = attendance.completionPercentage;
    final statusColor = pct >= 100
        ? AppTheme.successGreen
        : pct > 0
            ? AppTheme.warningOrange
            : AppTheme.dangerRed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                pct >= 100
                    ? Icons.check_circle_rounded
                    : Icons.timelapse_rounded,
                color: statusColor,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pct >= 100
                          ? 'Goal Achieved!'
                          : '${pct.toStringAsFixed(0)}% Complete',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: statusColor),
                    ),
                    Text(
                      'ODC: ${DateTimeUtils.formatDuration(attendance.odcTime)}  '
                      '·  Break: ${DateTimeUtils.formatDuration(attendance.breakTime)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Check in / out
        Row(
          children: [
            _TimeChip(
              icon: Icons.login_rounded,
              label: 'Check In',
              time: attendance.checkIn != null
                  ? DateTimeUtils.formatTime12Hour(attendance.checkIn!)
                  : '--',
              color: AppTheme.successGreen,
            ),
            const SizedBox(width: 12),
            _TimeChip(
              icon: Icons.logout_rounded,
              label: 'Check Out',
              time: attendance.checkOut != null
                  ? DateTimeUtils.formatTime12Hour(attendance.checkOut!)
                  : '--',
              color: AppTheme.dangerRed,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Sessions
        if (attendance.sessions.isNotEmpty) ...[
          Text('Sessions', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          ...attendance.sessions.map((s) {
            final isOdc = s.type == 'odc';
            final color = isOdc
                ? AppTheme.primaryBlue
                : AppTheme.warningOrange;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                      isOdc
                          ? Icons.work_outline_rounded
                          : Icons.coffee_outlined,
                      color: color,
                      size: 18),
                  const SizedBox(width: 8),
                  Text(
                    isOdc ? 'Work' : 'Break',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: color),
                  ),
                  const Spacer(),
                  Text(
                    '${DateTimeUtils.formatTime12Hour(s.startTime)}'
                    '${s.endTime != null ? ' → ${DateTimeUtils.formatTime12Hour(s.endTime!)}' : ' (ongoing)'}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final Color color;

  const _TimeChip(
      {required this.icon,
      required this.label,
      required this.time,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: color)),
            Text(time,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
