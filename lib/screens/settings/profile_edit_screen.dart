import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _employeeIdCtrl;
  late TextEditingController _shiftStartCtrl;
  late TextEditingController _shiftEndCtrl;
  late TextEditingController _dailyGoalCtrl;
  late TextEditingController _breakLimitCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _employeeIdCtrl = TextEditingController();
    _shiftStartCtrl = TextEditingController(text: '13:00');
    _shiftEndCtrl = TextEditingController(text: '22:00');
    _dailyGoalCtrl = TextEditingController(text: '480');
    _breakLimitCtrl = TextEditingController(text: '60');

    // Pre-fill from profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile != null) {
        _nameCtrl.text = profile.fullName;
        _employeeIdCtrl.text = profile.employeeId ?? '';
        _shiftStartCtrl.text = profile.shiftStart;
        _shiftEndCtrl.text = profile.shiftEnd;
        _dailyGoalCtrl.text = profile.dailyGoal.toString();
        _breakLimitCtrl.text = profile.breakLimit.toString();
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _employeeIdCtrl.dispose();
    _shiftStartCtrl.dispose();
    _shiftEndCtrl.dispose();
    _dailyGoalCtrl.dispose();
    _breakLimitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);
    try {
      final dailyGoal = int.tryParse(_dailyGoalCtrl.text.trim()) ?? 480;
      final breakLimit = int.tryParse(_breakLimitCtrl.text.trim()) ?? 60;

      await ref.read(authServiceProvider).updateUserProfile(uid, {
        'fullName': _nameCtrl.text.trim(),
        'employeeId': _employeeIdCtrl.text.trim().isEmpty
            ? null
            : _employeeIdCtrl.text.trim(),
        'shiftStart': _shiftStartCtrl.text.trim(),
        'shiftEnd': _shiftEndCtrl.text.trim(),
        'dailyGoal': dailyGoal.clamp(60, 1440),
        'breakLimit': breakLimit.clamp(10, 240),
      });

      // Refresh profile cache
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.dangerRed,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final parts = ctrl.text.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 0,
      minute: int.tryParse(parts.last) ?? 0,
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
      ctrl.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save',
                  style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppTheme.primaryBlue,
                      child: Text(
                        (profile?.fullName.isNotEmpty == true)
                            ? profile!.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (profile != null)
                Text(profile.mobileNumber,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6))),
              const SizedBox(height: 28),

              // Full Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Employee ID
              TextFormField(
                controller: _employeeIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Employee ID (optional)',
                  prefixIcon: Icon(Icons.badge_rounded),
                ),
              ),
              const SizedBox(height: 24),

              // Shift timing
              Text('Shift Timing',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: AppTheme.primaryBlue)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _shiftStartCtrl,
                      readOnly: true,
                      onTap: () => _pickTime(_shiftStartCtrl),
                      decoration: const InputDecoration(
                        labelText: 'Shift Start',
                        prefixIcon: Icon(Icons.login_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _shiftEndCtrl,
                      readOnly: true,
                      onTap: () => _pickTime(_shiftEndCtrl),
                      decoration: const InputDecoration(
                        labelText: 'Shift End',
                        prefixIcon: Icon(Icons.logout_rounded),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Goals
              Text('Daily Goals',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: AppTheme.primaryBlue)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dailyGoalCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Daily Goal (min)',
                        prefixIcon: Icon(Icons.flag_rounded),
                        helperText: '480 = 8h',
                      ),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 60) return 'Min 60 min';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _breakLimitCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Break Limit (min)',
                        prefixIcon: Icon(Icons.coffee_rounded),
                        helperText: '60 = 1h',
                      ),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 10) return 'Min 10 min';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Read-only info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _infoRow(context, 'Mobile Number',
                        profile?.mobileNumber ?? '-',
                        Icons.phone_rounded),
                    const Divider(height: 20),
                    _infoRow(context, 'Account Created',
                        profile != null
                            ? '${profile.createdAt.day}/${profile.createdAt.month}/${profile.createdAt.year}'
                            : '-',
                        Icons.calendar_today_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
      BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon,
            color:
                theme.colorScheme.onSurface.withValues(alpha: 0.4),
            size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5))),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        const Icon(Icons.lock_outline_rounded, size: 14),
      ],
    );
  }
}
