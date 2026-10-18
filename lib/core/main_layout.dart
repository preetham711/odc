import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/biometric_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/app_lock_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/tasks/tasks_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/admin/admin_layout.dart';
import '../theme/app_theme.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  DateTime? _backgroundedAt;

  List<Widget> _getScreens(bool isAdmin) {
    final baseScreens = const [
      HomeScreen(),
      CalendarScreen(),
      ReportsScreen(),
      TasksScreen(),
      ProfileScreen(),
    ];
    
    if (isAdmin) {
      return [...baseScreens, const AdminLayout()];
    }
    return baseScreens;
  }

  List<_NavItem> _getNavItems(bool isAdmin) {
    const baseItems = [
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Today',
      ),
      _NavItem(
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month_rounded,
        label: 'Calendar',
      ),
      _NavItem(
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        label: 'Reports',
      ),
      _NavItem(
        icon: Icons.checklist_outlined,
        activeIcon: Icons.checklist_rounded,
        label: 'Tasks',
      ),
      _NavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
      ),
    ];
    
    if (isAdmin) {
      return [
        ...baseItems,
        const _NavItem(
          icon: CupertinoIcons.settings,
          activeIcon: CupertinoIcons.settings_solid,
          label: 'Admin',
        ),
      ];
    }
    return baseItems;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lockEnabled = ref.read(appLockEnabledProvider);
    if (!lockEnabled) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final backgrounded = _backgroundedAt;
      if (backgrounded != null) {
        final elapsed = DateTime.now().difference(backgrounded).inSeconds;
        // Lock after 60 seconds in background
        if (elapsed > 60) {
          ref.read(sessionUnlockedProvider.notifier).state = false;
        }
      }
      _backgroundedAt = null;
    }
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userProfile = ref.watch(userProfileProvider);
    
    // Handle loading and error states
    final isAdmin = userProfile.when(
      data: (profile) => profile?.isAdmin ?? false,
      loading: () => false,
      error: (_, __) => false,
    );
    
    final screens = _getScreens(isAdmin);
    final navItems = _getNavItems(isAdmin);

    return AppLockScreen(
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        bottomNavigationBar: _PremiumNavBar(
          currentIndex: _currentIndex,
          items: navItems,
          isDark: isDark,
          onTap: _onTabSelected,
        ),
      ),
    );
  }
}

// ─── Premium iOS-style Nav Bar ────────────────────────────────────────────────
class _PremiumNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _PremiumNavBar({
    required this.currentIndex,
    required this.items,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.95)
            : AppColors.surfaceLight.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.separatorDark
                : AppColors.separatorLight,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = currentIndex == i;
              return Expanded(
                child: _NavButton(
                  item: items[i],
                  selected: selected,
                  isDark: isDark,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.85)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.selected
        ? AppColors.accent
        : (widget.isDark
            ? AppColors.label3Dark
            : AppColors.label3Light);

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.selected ? 44 : 36,
              height: widget.selected ? 30 : 26,
              decoration: BoxDecoration(
                color: widget.selected
                    ? AppColors.accent.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.selected
                    ? widget.item.activeIcon
                    : widget.item.icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: widget.selected
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: color,
              ),
              child: Text(widget.item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
