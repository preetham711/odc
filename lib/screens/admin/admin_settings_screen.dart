import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ios_widgets.dart';
import 'admin_schedules_screen.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.adminOrange,
        foregroundColor: Colors.white,
        title: const Text('Admin Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Work Schedules
          IOSCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Work Schedules', style: AppTypography.h3),
                const SizedBox(height: 8),
                Text(
                  'Manage organization work schedules',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                IOSButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminSchedulesScreen(),
                      ),
                    );
                  },
                  text: 'Manage Schedules',
                  icon: CupertinoIcons.calendar,
                  variant: IOSButtonVariant.secondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Organization Settings (Placeholder)
          IOSCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Organization', style: AppTypography.h3),
                const SizedBox(height: 8),
                Text(
                  'Organization settings and preferences',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSettingRow(
                  icon: CupertinoIcons.building_2_fill,
                  label: 'Company Name',
                  value: 'ODC Tracker',
                  onTap: () {
                    // TODO: Implement
                  },
                ),
                const Divider(height: 24),
                _buildSettingRow(
                  icon: CupertinoIcons.time,
                  label: 'Default Shift Hours',
                  value: '13:00 - 22:00',
                  onTap: () {
                    // TODO: Implement
                  },
                ),
                const Divider(height: 24),
                _buildSettingRow(
                  icon: CupertinoIcons.clock,
                  label: 'Daily Goal',
                  value: '8 hours',
                  onTap: () {
                    // TODO: Implement
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Notifications (Placeholder)
          IOSCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notifications', style: AppTypography.h3),
                const SizedBox(height: 8),
                Text(
                  'Admin notification preferences',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSettingRow(
                  icon: CupertinoIcons.bell_fill,
                  label: 'Daily Reports',
                  value: 'Enabled',
                  onTap: () {
                    // TODO: Implement
                  },
                ),
                const Divider(height: 24),
                _buildSettingRow(
                  icon: CupertinoIcons.exclamationmark_triangle_fill,
                  label: 'Alerts',
                  value: 'Enabled',
                  onTap: () {
                    // TODO: Implement
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.adminOrange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: AppTypography.body),
            ),
            Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
