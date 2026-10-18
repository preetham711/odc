import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service_enhanced.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ios_widgets.dart';

/// Audit Logs Screen - Shows all admin actions
class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  final _adminService = AdminServiceEnhanced();
  String? _filterAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.adminOrange,
        foregroundColor: Colors.white,
        title: const Text('Audit Logs'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.line_horizontal_3_decrease),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: StreamBuilder<List<AuditLog>>(
        stream: _adminService.streamAuditLogs(
          action: _filterAction,
          limit: 100,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CupertinoActivityIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading logs',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.doc_text,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No audit logs yet',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildLogCard(log);
            },
          ).animate().fadeIn();
        },
      ),
    );
  }

  Widget _buildLogCard(AuditLog log) {
    final actionColor = _getActionColor(log.action);
    final actionIcon = _getActionIcon(log.action);
    final actionLabel = _getActionLabel(log.action);

    return IOSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: actionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  actionIcon,
                  size: 20,
                  color: actionColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      actionLabel,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM dd, yyyy • h:mm a').format(log.timestamp),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: actionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  log.action.replaceAll('_', ' ').toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: actionColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (log.metadata.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (log.targetUserId != null) ...[
                    _buildMetaRow('Target User', log.targetUserId!),
                  ],
                  ...log.metadata.entries.map((e) =>
                      _buildMetaRow(e.key, e.value.toString())),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    if (action.contains('delete')) return AppColors.error;
    if (action.contains('disable')) return AppColors.warning;
    if (action.contains('role') || action.contains('admin')) {
      return AppColors.adminOrange;
    }
    if (action.contains('enable') || action.contains('update')) {
      return AppColors.success;
    }
    return AppColors.accent;
  }

  IconData _getActionIcon(String action) {
    if (action.contains('delete')) return CupertinoIcons.trash;
    if (action.contains('disable')) return CupertinoIcons.xmark_shield;
    if (action.contains('enable')) return CupertinoIcons.checkmark_shield;
    if (action.contains('role')) return CupertinoIcons.star;
    if (action.contains('update')) return CupertinoIcons.pencil;
    return CupertinoIcons.doc_text;
  }

  String _getActionLabel(String action) {
    final words = action.split('_');
    return words.map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  void _showFilterSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: AppColors.surfaceLight,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.border,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filter Logs', style: AppTypography.h3),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() => _filterAction = null);
                        Navigator.pop(context);
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    _buildFilterOption('All Actions', null),
                    _buildFilterOption('User Deleted', 'user_deleted'),
                    _buildFilterOption('User Disabled', 'user_disabled'),
                    _buildFilterOption('User Enabled', 'user_enabled'),
                    _buildFilterOption('User Updated', 'user_updated'),
                    _buildFilterOption('Role Changed', 'role_changed'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, String? action) {
    final isSelected = _filterAction == action;
    return CupertinoButton(
      onPressed: () {
        setState(() => _filterAction = action);
        Navigator.pop(context);
      },
      child: Row(
        children: [
          Icon(
            isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
            color: isSelected ? AppColors.adminOrange : AppColors.textTertiary,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTypography.body.copyWith(
              color: isSelected ? AppColors.adminOrange : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
