import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/attendance_model.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ios_widgets.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const UserDetailScreen({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  final _adminService = AdminService();
  bool _isLoading = false;

  Future<void> _toggleUserStatus() async {
    final shouldDisable = !widget.user.isDisabled;
    final action = shouldDisable ? 'disable' : 'enable';

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('${action.substring(0, 1).toUpperCase()}${action.substring(1)} User'),
        content: Text('Are you sure you want to $action ${widget.user.fullName}?'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: shouldDisable,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _adminService.updateUser(
        widget.user.uid,
        {'isDisabled': shouldDisable},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${shouldDisable ? 'disabled' : 'enabled'} successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update user: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAdminStatus() async {
    final shouldMakeAdmin = !widget.user.isAdmin;
    final action = shouldMakeAdmin ? 'grant admin access to' : 'revoke admin access from';

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('${shouldMakeAdmin ? 'Grant' : 'Revoke'} Admin Access'),
        content: Text('Are you sure you want to $action ${widget.user.fullName}?'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: !shouldMakeAdmin,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _adminService.updateUser(
        widget.user.uid,
        {'role': shouldMakeAdmin ? 'admin' : 'user'},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Admin access ${shouldMakeAdmin ? 'granted' : 'revoked'} successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update user: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editField(String field, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    
    final newValue = await showCupertinoDialog<String>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Edit ${field.substring(0, 1).toUpperCase()}${field.substring(1)}'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: field.substring(0, 1).toUpperCase() + field.substring(1),
            keyboardType: field == 'mobileNumber' ? TextInputType.phone : TextInputType.text,
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newValue == null || newValue.isEmpty || newValue == currentValue) return;

    setState(() => _isLoading = true);
    try {
      await _adminService.updateUser(
        widget.user.uid,
        {field: newValue},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${field.substring(0, 1).toUpperCase()}${field.substring(1)} updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update $field: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.adminOrange,
        foregroundColor: Colors.white,
        title: const Text('User Details'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Card
              IOSCard(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: widget.user.isDisabled 
                        ? AppColors.textTertiary 
                        : AppColors.adminOrange,
                      child: Text(
                        widget.user.fullName.substring(0, 1).toUpperCase(),
                        style: AppTypography.h1.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.user.fullName,
                      style: AppTypography.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user.email ?? '',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.user.isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.adminOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.star_fill,
                                  size: 14,
                                  color: AppColors.adminOrange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Admin',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.adminOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (widget.user.isAdmin && widget.user.isDisabled)
                          const SizedBox(width: 8),
                        if (widget.user.isDisabled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Disabled',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Contact Information
              IOSCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contact Information', style: AppTypography.h3),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: CupertinoIcons.phone_fill,
                      label: 'Phone',
                      value: widget.user.mobileNumber.isNotEmpty ? widget.user.mobileNumber : 'Not set',
                      onTap: () => _editField('mobileNumber', widget.user.mobileNumber),
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      icon: CupertinoIcons.mail_solid,
                      label: 'Email',
                      value: widget.user.email ?? 'Not set',
                      onTap: () => _editField('email', widget.user.email ?? ''),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Account Information
              IOSCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account Information', style: AppTypography.h3),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: CupertinoIcons.calendar,
                      label: 'Joined',
                      value: DateFormat('MMM dd, yyyy').format(widget.user.createdAt),
                      showArrow: false,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      icon: CupertinoIcons.time,
                      label: 'Last Updated',
                      value: DateFormat('MMM dd, yyyy').format(widget.user.updatedAt),
                      showArrow: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Recent Activity
              IOSCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Activity', style: AppTypography.h3),
                    const SizedBox(height: 16),
                    FutureBuilder<List<AttendanceModel>>(
                      future: _adminService.getUserAttendance(
                        widget.user.uid,
                        from: DateTime.now().subtract(const Duration(days: 30)),
                        to: DateTime.now(),
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CupertinoActivityIndicator(),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'No activity yet',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }

                        final records = snapshot.data!.take(5).toList();
                        return Column(
                          children: records.asMap().entries.map((entry) {
                            final index = entry.key;
                            final record = entry.value;
                            return Column(
                              children: [
                                if (index > 0) const Divider(height: 24),
                                _buildActivityRow(record),
                              ],
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Admin Actions
              IOSCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin Actions', style: AppTypography.h3),
                    const SizedBox(height: 16),
                    IOSButton(
                      onPressed: _toggleAdminStatus,
                      text: widget.user.isAdmin ? 'Revoke Admin Access' : 'Grant Admin Access',
                      icon: widget.user.isAdmin ? CupertinoIcons.star_slash : CupertinoIcons.star,
                      variant: IOSButtonVariant.secondary,
                    ),
                    const SizedBox(height: 12),
                    IOSButton(
                      onPressed: _toggleUserStatus,
                      text: widget.user.isDisabled ? 'Enable User' : 'Disable User',
                      icon: widget.user.isDisabled ? CupertinoIcons.checkmark_shield : CupertinoIcons.xmark_shield,
                      variant: IOSButtonVariant.destructive,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CupertinoActivityIndicator(radius: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    bool showArrow = true,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(value, style: AppTypography.body),
                ],
              ),
            ),
            if (showArrow && onTap != null)
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

  Widget _buildActivityRow(AttendanceModel record) {
    final date = DateFormat('MMM dd').format(record.date);
    final checkIn = record.checkIn != null
        ? DateFormat('h:mm a').format(record.checkIn!)
        : 'Not checked in';
    final checkOut = record.checkOut != null
        ? DateFormat('h:mm a').format(record.checkOut!)
        : 'Not checked out';

    final totalHours = record.odcTime / 60.0;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.adminOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            CupertinoIcons.calendar,
            size: 20,
            color: AppColors.adminOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: AppTypography.body),
              const SizedBox(height: 2),
              Text(
                '$checkIn - $checkOut',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (totalHours > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${totalHours.toStringAsFixed(1)}h',
              style: AppTypography.caption.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
