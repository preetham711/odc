import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/work_schedule.dart';
import '../../providers/auth_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../theme/app_theme.dart';

class WorkScheduleScreen extends ConsumerWidget {
  const WorkScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final schedulesAsync = ref.watch(schedulesProvider);
    final activeAsync = ref.watch(activeScheduleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Schedules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _openEditor(context, ref),
          ),
        ],
      ),
      body: schedulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (schedules) {
          if (schedules.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 48,
                      color: isDark
                          ? AppColors.label3Dark
                          : AppColors.label3Light),
                  const SizedBox(height: 16),
                  Text('No schedules yet',
                      style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? AppColors.label3Dark
                              : AppColors.label3Light)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _seedDefaults(context, ref),
                    child: const Text('Add default schedules'),
                  ),
                ],
              ),
            );
          }

          final active = activeAsync.valueOrNull;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Active schedule info ──────────────────────────────
              if (active != null) ...[
                _SectionHeader(title: 'Active Today'),
                const SizedBox(height: 10),
                _ScheduleCard(
                  schedule: active,
                  isActive: true,
                  isDark: isDark,
                  onEdit: () => _openEditor(context, ref, schedule: active),
                  onDelete: null, // can't delete active
                ),
                const SizedBox(height: 20),
              ],

              _SectionHeader(title: 'All Schedules'),
              const SizedBox(height: 10),
              ...schedules.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ScheduleCard(
                      schedule: s,
                      isActive: s.id == active?.id,
                      isDark: isDark,
                      onEdit: () =>
                          _openEditor(context, ref, schedule: s),
                      onDelete: schedules.length > 1
                          ? () => _delete(context, ref, s)
                          : null,
                    ),
                  )),
              const SizedBox(height: 10),

              // Info about auto-switching
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.accent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Schedules switch automatically based on their effective dates. '
                        'Historical reports always use the schedule that was active on that date.',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.accent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _seedDefaults(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    await ref.read(firestoreServiceProvider).seedDefaultSchedules(uid);
    ref.invalidate(schedulesProvider);
    ref.invalidate(activeScheduleProvider);
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref,
      {WorkSchedule? schedule}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ScheduleEditorScreen(schedule: schedule)),
    );
    ref.invalidate(schedulesProvider);
    ref.invalidate(activeScheduleProvider);
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, WorkSchedule s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text('Delete "${s.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(scheduleNotifierProvider.notifier).delete(s.id);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
      );
}

class _ScheduleCard extends StatelessWidget {
  final WorkSchedule schedule;
  final bool isActive;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _ScheduleCard({
    required this.schedule,
    required this.isActive,
    required this.isDark,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isActive
        ? AppColors.success.withValues(alpha: 0.5)
        : (isDark ? AppColors.separatorDark : AppColors.separatorLight);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: isActive ? 1.5 : 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + status
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(schedule.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700)),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    if (!schedule.enabled) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'DISABLED',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 18),
                onPressed: onEdit,
                color: AppColors.accent,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.danger),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // Time display
          Row(
            children: [
              _detail(context, Icons.access_time_rounded,
                  schedule.displayTime),
              const SizedBox(width: 20),
              _detail(context, Icons.flag_rounded,
                  '${schedule.requiredOdcMinutes ~/ 60}h ODC'),
              const SizedBox(width: 20),
              _detail(context, Icons.coffee_rounded,
                  '${schedule.allowedBreakMinutes}m break'),
            ],
          ),
          // Effective dates
          if (schedule.effectiveFrom != null ||
              schedule.effectiveUntil != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 12,
                    color: isDark
                        ? AppColors.label3Dark
                        : AppColors.label3Light),
                const SizedBox(width: 6),
                Text(
                  _formatDateRange(schedule),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _detail(BuildContext ctx, IconData icon, String label) {
    final theme = Theme.of(ctx);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 13,
            color: isDark ? AppColors.label3Dark : AppColors.label3Light),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.labelMedium),
      ],
    );
  }

  String _formatDateRange(WorkSchedule s) {
    final fmt = DateFormat('dd MMM yyyy');
    if (s.effectiveFrom != null && s.effectiveUntil != null) {
      return '${fmt.format(s.effectiveFrom!)} → ${fmt.format(s.effectiveUntil!)}';
    }
    if (s.effectiveFrom != null) {
      return 'From ${fmt.format(s.effectiveFrom!)}';
    }
    if (s.effectiveUntil != null) {
      return 'Until ${fmt.format(s.effectiveUntil!)}';
    }
    return '';
  }
}

// ─── Schedule Editor ──────────────────────────────────────────────────────────
class ScheduleEditorScreen extends ConsumerStatefulWidget {
  final WorkSchedule? schedule;
  const ScheduleEditorScreen({super.key, this.schedule});

  @override
  ConsumerState<ScheduleEditorScreen> createState() =>
      _ScheduleEditorScreenState();
}

class _ScheduleEditorScreenState
    extends ConsumerState<ScheduleEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late String _startTime;
  late String _endTime;
  late int _requiredOdcMinutes;
  late int _allowedBreakMinutes;
  DateTime? _effectiveFrom;
  DateTime? _effectiveUntil;
  late bool _enabled;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _startTime = s?.startTime ?? '13:00';
    _endTime = s?.endTime ?? '22:00';
    _requiredOdcMinutes = s?.requiredOdcMinutes ?? 480;
    _allowedBreakMinutes = s?.allowedBreakMinutes ?? 60;
    _effectiveFrom = s?.effectiveFrom;
    _effectiveUntil = s?.effectiveUntil;
    _enabled = s?.enabled ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final parts = (isStart ? _startTime : _endTime).split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      final str =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) { _startTime = str; } else { _endTime = str; }
      });
    }
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          (isFrom ? _effectiveFrom : _effectiveUntil) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) { _effectiveFrom = picked; } else { _effectiveUntil = picked; }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final schedule = WorkSchedule(
        id: widget.schedule?.id ?? const Uuid().v4(),
        userId: uid,
        name: _nameCtrl.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
        requiredOdcMinutes: _requiredOdcMinutes,
        allowedBreakMinutes: _allowedBreakMinutes,
        effectiveFrom: _effectiveFrom,
        effectiveUntil: _effectiveUntil,
        enabled: _enabled,
        createdAt: widget.schedule?.createdAt ?? now,
        updatedAt: now,
      );
      await ref.read(scheduleNotifierProvider.notifier).save(schedule);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.schedule == null ? 'New Schedule' : 'Edit Schedule'),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _save,
                  child: Text('Save',
                      style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700)),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Schedule Name',
                  hintText: 'e.g. Schedule A, April Schedule',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              // Times
              Text('Shift Hours', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TimePicker(
                      label: 'Start Time',
                      value: _startTime,
                      isDark: isDark,
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimePicker(
                      label: 'End Time',
                      value: _endTime,
                      isDark: isDark,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Goals
              Text('Requirements', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _NumberInput(
                label: 'Required ODC (minutes)',
                value: _requiredOdcMinutes,
                min: 60,
                max: 720,
                step: 30,
                onChanged: (v) => setState(() => _requiredOdcMinutes = v),
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _NumberInput(
                label: 'Break Allowance (minutes)',
                value: _allowedBreakMinutes,
                min: 15,
                max: 240,
                step: 15,
                onChanged: (v) => setState(() => _allowedBreakMinutes = v),
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              // Effective dates
              Text('Effective Dates', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Leave empty for an always-active schedule.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DateChip(
                      label: 'Effective From',
                      date: _effectiveFrom,
                      isDark: isDark,
                      onTap: () => _pickDate(true),
                      onClear: () => setState(() => _effectiveFrom = null),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateChip(
                      label: 'Effective Until',
                      date: _effectiveUntil,
                      isDark: isDark,
                      onTap: () => _pickDate(false),
                      onClear: () => setState(() => _effectiveUntil = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Enabled switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(Icons.toggle_on_rounded, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text('Enabled',
                            style: theme.textTheme.titleMedium)),
                    Switch.adaptive(
                      value: _enabled,
                      onChanged: (v) => setState(() => _enabled = v),
                      thumbColor: WidgetStateProperty.resolveWith(
                        (s) => s.contains(WidgetState.selected)
                            ? Colors.white
                            : null,
                      ),
                      trackColor: WidgetStateProperty.resolveWith(
                        (s) => s.contains(WidgetState.selected)
                            ? AppColors.accent
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final VoidCallback onTap;

  const _TimePicker({
    required this.label,
    required this.value,
    required this.isDark,
    required this.onTap,
  });

  String _fmt(String hhmm) {
    try {
      final parts = hhmm.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final period = h < 12 ? 'AM' : 'PM';
      final h12 = h % 12 == 0 ? 12 : h % 12;
      return m == 0
          ? '$h12:00 $period'
          : '$h12:${m.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return hhmm;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(_fmt(value),
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.accent, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberInput extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;
  final bool isDark;

  const _NumberInput({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = value ~/ 60;
    final m = value % 60;
    final display = h > 0
        ? '${h}h ${m > 0 ? '${m}m' : ''}'.trim()
        : '${m}m';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(display,
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Row(
            children: [
              _stepper(Icons.remove_rounded, () {
                if (value - step >= min) onChanged(value - step);
              }),
              const SizedBox(width: 8),
              _stepper(Icons.add_rounded, () {
                if (value + step <= max) onChanged(value + step);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepper(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.accent),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final DateTime? date;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateChip({
    required this.label,
    this.date,
    required this.isDark,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    date != null
                        ? DateFormat('dd MMM yyyy').format(date!)
                        : 'Not set',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: date != null
                          ? AppColors.accent
                          : (isDark
                              ? AppColors.label3Dark
                              : AppColors.label3Light),
                      fontWeight: date != null ? FontWeight.w600 : null,
                    ),
                  ),
                ),
                if (date != null)
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(Icons.clear_rounded,
                        size: 16, color: AppColors.danger),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
