import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/reminder_provider.dart';
import '../../theme/app_theme.dart';

class BreakReminderSettingsScreen extends ConsumerWidget {
  const BreakReminderSettingsScreen({super.key});

  static const _intervals = [5, 10, 15, 20, 30, 45, 60];
  static const _maxDurations = [0, 30, 60, 120]; // 0 = unlimited
  static const _hours = [
    '12 AM', '1 AM', '2 AM', '3 AM', '4 AM', '5 AM', '6 AM', '7 AM',
    '8 AM', '9 AM', '10 AM', '11 AM', '12 PM', '1 PM', '2 PM', '3 PM',
    '4 PM', '5 PM', '6 PM', '7 PM', '8 PM', '9 PM', '10 PM', '11 PM',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = ref.watch(reminderSettingsProvider);
    final notifier = ref.read(reminderSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Break Reminder')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Main toggle ──────────────────────────────────────────────
          _card(
            context,
            child: SwitchListTile(
              value: s.enabled,
              onChanged: (v) => notifier.toggle(v),
              title: const Text('Enable Break Reminder',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text(
                  'Get notified when you stay outside the ODC too long'),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  s.enabled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_rounded,
                  color: AppTheme.primaryBlue,
                ),
              ),
              activeThumbColor: AppTheme.primaryBlue,
              activeTrackColor: AppTheme.primaryBlue.withValues(alpha: 0.4),
            ),
          ),

          if (s.enabled) ...[
            const SizedBox(height: 16),

            // ── Reminder Interval ──────────────────────────────────────
            _section(context, 'Reminder Interval',
                'How often to remind you while on break'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _intervals.map((min) {
                final selected = s.intervalMinutes == min;
                return ChoiceChip(
                  label: Text('$min min'),
                  selected: selected,
                  onSelected: (_) => notifier.setInterval(min),
                  selectedColor: AppTheme.primaryBlue,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : null,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Vibration ─────────────────────────────────────────────
            _card(
              context,
              child: SwitchListTile(
                value: s.vibration,
                onChanged: (v) => notifier.setVibration(v),
                title: const Text('Vibration'),
                subtitle: const Text('Vibrate with reminder notifications'),
                secondary: const Icon(Icons.vibration_rounded,
                    color: AppTheme.primaryBlue),
                activeThumbColor: AppTheme.primaryBlue,
                activeTrackColor: AppTheme.primaryBlue.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 12),

            // ── Repeat Until Return ───────────────────────────────────
            _card(
              context,
              child: SwitchListTile(
                value: s.repeatUntilReturn,
                onChanged: (v) => notifier.setRepeat(v),
                title: const Text('Repeat Until Return'),
                subtitle: const Text(
                    'Keep reminding until you tap "I\'m IN"'),
                secondary: const Icon(Icons.repeat_rounded,
                    color: AppTheme.primaryBlue),
                activeThumbColor: AppTheme.primaryBlue,
                activeTrackColor: AppTheme.primaryBlue.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 20),

            // ── Max Reminder Duration ─────────────────────────────────
            _section(context, 'Maximum Reminder Duration',
                'Stop reminders after this duration (0 = unlimited)'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _maxDurations.map((min) {
                final selected = s.maxDurationMinutes == min;
                final label = min == 0
                    ? 'Unlimited'
                    : min == 30
                        ? '30 min'
                        : min == 60
                            ? '1 hour'
                            : '2 hours';
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => notifier.setMaxDuration(min),
                  selectedColor: AppTheme.primaryBlue,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : null,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Quiet Hours ────────────────────────────────────────────
            _card(
              context,
              child: Column(
                children: [
                  SwitchListTile(
                    value: s.quietHoursEnabled,
                    onChanged: (v) =>
                        notifier.setQuietHours(v, s.quietStart, s.quietEnd),
                    title: const Text('Quiet Hours'),
                    subtitle: Text(
                      s.quietHoursEnabled
                          ? 'No reminders ${_hours[s.quietStart]} – ${_hours[s.quietEnd]}'
                          : 'Disable reminders during selected hours',
                    ),
                    secondary: const Icon(Icons.do_not_disturb_rounded,
                        color: AppTheme.primaryBlue),
                    activeThumbColor: AppTheme.primaryBlue,
                    activeTrackColor:
                        AppTheme.primaryBlue.withValues(alpha: 0.4),
                  ),
                  if (s.quietHoursEnabled) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Start',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                            color: AppTheme.primaryBlue)),
                                const SizedBox(height: 6),
                                DropdownButton<int>(
                                  value: s.quietStart,
                                  isExpanded: true,
                                  items: List.generate(
                                      24,
                                      (i) => DropdownMenuItem(
                                          value: i,
                                          child: Text(_hours[i]))),
                                  onChanged: (v) => notifier.setQuietHours(
                                      s.quietHoursEnabled,
                                      v ?? s.quietStart,
                                      s.quietEnd),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('End',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                            color: AppTheme.primaryBlue)),
                                const SizedBox(height: 6),
                                DropdownButton<int>(
                                  value: s.quietEnd,
                                  isExpanded: true,
                                  items: List.generate(
                                      24,
                                      (i) => DropdownMenuItem(
                                          value: i,
                                          child: Text(_hours[i]))),
                                  onChanged: (v) => notifier.setQuietHours(
                                      s.quietHoursEnabled,
                                      s.quietStart,
                                      v ?? s.quietEnd),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── Escalation Info ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.warningOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppTheme.warningOrange.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppTheme.warningOrange, size: 20),
                  const SizedBox(width: 8),
                  Text('Smart Escalation (always active)',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: AppTheme.warningOrange)),
                ]),
                const SizedBox(height: 10),
                _escalationRow(context, '30 min',
                    'Break has exceeded 30 minutes', AppTheme.warningOrange),
                _escalationRow(context, '45 min',
                    'ODC target may be affected', AppTheme.warningOrange),
                _escalationRow(context, '60 min',
                    '1-hour break limit reached', AppTheme.dangerRed),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _section(BuildContext context, String title, String subtitle) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _escalationRow(
      BuildContext context, String time, String msg, Color color) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(time,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
