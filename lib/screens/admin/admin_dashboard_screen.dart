import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/ios_widgets.dart';
import '../auth/login_screen.dart';

// Admin accent colour — distinct from user app to make it obvious
const _kAdmin = Color(0xFFFF6B35);
const _kAdminDark = Color(0xFFE55A25);

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final statsAsync = ref.watch(adminStatsProvider);
    final allUsersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminStatsProvider);
            ref.invalidate(allUsersProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Admin header ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: _AdminHeader(
                  adminName: profile?.fullName ?? 'Admin',
                  isDark: isDark,
                ).animate().fadeIn(duration: 400.ms),
              ),

              // ── Stats grid ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: statsAsync.when(
                    loading: () => _StatsGrid.skeleton(),
                    error: (e, _) => _ErrorBanner('Failed to load stats: $e'),
                    data: (stats) => stats == null
                        ? const SizedBox.shrink()
                        : _StatsGrid(stats: stats).animate()
                            .fadeIn(delay: 100.ms),
                  ),
                ),
              ),

              // ── Live status ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Live Status', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 12),
                      allUsersAsync.when(
                        loading: () => const _ShimmerList(),
                        error: (e, _) => _ErrorBanner('$e'),
                        data: (users) => _LiveUserList(
                          users: users
                              .where((u) => !u.isAdmin)
                              .toList(),
                        ).animate().fadeIn(delay: 200.ms),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Admin Header ──────────────────────────────────────────────────────────────
class _AdminHeader extends StatelessWidget {
  final String adminName;
  final bool isDark;
  const _AdminHeader({required this.adminName, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kAdmin.withValues(alpha: 0.15),
            _kAdmin.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kAdmin, _kAdminDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.elevated(_kAdmin),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kAdmin.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ADMIN',
                        style: TextStyle(
                          color: _kAdmin,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  adminName,
                  style: theme.textTheme.headlineMedium,
                ),
                Text(
                  DateTimeUtils.formatDateLong(DateTime.now()),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Grid ───────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final AdminStats? stats;
  const _StatsGrid({this.stats});

  factory _StatsGrid.skeleton() => const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.8,
        children: List.generate(
            6, (_) => ShimmerCard(height: 80, borderRadius: 16)),
      );
    }

    final items = [
      _StatTile('Total Users', '${stats!.totalUsers}',
          Icons.group_rounded, _kAdmin),
      _StatTile('Checked In', '${stats!.checkedInToday}',
          Icons.login_rounded, AppColors.success),
      _StatTile('On Break', '${stats!.onBreakNow}',
          Icons.coffee_rounded, AppColors.warning),
      _StatTile('Active Users', '${stats!.activeUsers}',
          Icons.person_rounded, AppColors.accent),
      _StatTile(
        'ODC Today',
        DateTimeUtils.formatDuration(stats!.totalODCMinutesToday),
        Icons.schedule_rounded,
        AppColors.success,
      ),
      _StatTile(
        'Perfect Days',
        '${stats!.totalPerfectDaysThisMonth}',
        Icons.star_rounded,
        AppColors.warning,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: items.map((t) => _StatCard(tile: t)).toList(),
    );
  }
}

class _StatTile {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatTile(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatTile tile;
  const _StatCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tile.color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(tile.icon, color: tile.color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tile.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tile.color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tile.value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: tile.color,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Live User List ───────────────────────────────────────────────────────────
class _LiveUserList extends ConsumerWidget {
  final List<UserModel> users;
  const _LiveUserList({required this.users});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (users.isEmpty) {
      return const IOSCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('No users registered yet'),
          ),
        ),
      );
    }

    return Column(
      children: users.map((u) => _LiveUserTile(user: u)).toList(),
    );
  }
}

class _LiveUserTile extends ConsumerWidget {
  final UserModel user;
  const _LiveUserTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final attAsync = ref.watch(userTodayAttendanceProvider(user.uid));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppShadows.card(isDark),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kAdmin.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user.fullName.isNotEmpty
                      ? user.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: _kAdmin,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName,
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis),
                  Text(user.mobileNumber,
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            // Live status pill
            attAsync.when(
              loading: () => ShimmerCard(height: 24, width: 70),
              error: (_, __) => const SizedBox.shrink(),
              data: (att) => _StatusPill(att: att, isDark: isDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final AttendanceModel? att;
  final bool isDark;
  const _StatusPill({required this.att, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String label;
    Color color;

    if (att == null || !att!.isActive) {
      label = 'Offline';
      color = isDark ? AppColors.label3Dark : AppColors.label3Light;
    } else if (att!.sessions.isNotEmpty &&
        att!.sessions.last.type == 'break' &&
        att!.sessions.last.endTime == null) {
      label = 'Break';
      color = AppColors.warning;
    } else {
      label = 'Working';
      color = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label == 'Working')
            PulseDot(color: color, size: 5)
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) => Column(
        children: List.generate(
            4,
            (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ShimmerCard(height: 68, borderRadius: 14),
                )),
      );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.danger, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: AppColors.danger, fontSize: 13)),
            ),
          ],
        ),
      );
}
