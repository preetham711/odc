/// iOS-native component library for ODC Tracker AI.
/// Uses CupertinoActionSheet, CupertinoAlertDialog, iOS-style separators,
/// large title navigation, and platform-aware controls.

library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/ios_features_service.dart';
import '../theme/app_theme.dart';

// ─── iOS Action Sheet ─────────────────────────────────────────────────────────

/// Shows a native iOS-style bottom action sheet.
/// On Android it falls back to a Material BottomSheet.
Future<T?> showIOSActionSheet<T>({
  required BuildContext context,
  required String title,
  String? message,
  required List<IOSAction<T>> actions,
  IOSAction<T>? cancelAction,
}) {
  IOSFeaturesService.lightImpact();
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (_) => CupertinoActionSheet(
      title: Text(title),
      message: message != null ? Text(message) : null,
      actions: actions
          .map((a) => CupertinoActionSheetAction(
                isDestructiveAction: a.isDestructive,
                isDefaultAction: a.isDefault,
                onPressed: () {
                  Navigator.pop(context, a.value);
                  a.onPressed?.call();
                },
                child: Text(a.title),
              ))
          .toList(),
      cancelButton: cancelAction != null
          ? CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                cancelAction.onPressed?.call();
              },
              child: Text(cancelAction.title),
            )
          : CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
    ),
  );
}

class IOSAction<T> {
  final String title;
  final T? value;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final bool isDefault;

  const IOSAction({
    required this.title,
    this.value,
    this.onPressed,
    this.isDestructive = false,
    this.isDefault = false,
  });
}

// ─── iOS Alert ───────────────────────────────────────────────────────────────

Future<bool?> showIOSAlert({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  bool isDestructive = false,
}) {
  IOSFeaturesService.lightImpact();
  return showCupertinoDialog<bool>(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        CupertinoDialogAction(
          isDestructiveAction: isDestructive,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
}

// ─── iOS Bottom Sheet ─────────────────────────────────────────────────────────

/// Shows a premium iOS-style bottom sheet with drag handle.
Future<T?> showIOSBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isDismissible = true,
  double initialSize = 0.5,
  double maxSize = 0.92,
}) {
  IOSFeaturesService.lightImpact();
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _IOSBottomSheetContainer(
      initialSize: initialSize,
      maxSize: maxSize,
      child: child,
    ),
  );
}

class _IOSBottomSheetContainer extends StatelessWidget {
  final Widget child;
  final double initialSize;
  final double maxSize;

  const _IOSBottomSheetContainer({
    required this.child,
    required this.initialSize,
    required this.maxSize,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      initialChildSize: initialSize,
      minChildSize: 0.3,
      maxChildSize: maxSize,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.separatorDark
                        : AppColors.separatorLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── iOS Segmented Control ────────────────────────────────────────────────────

class IOSSegmentedControl<T> extends StatelessWidget {
  final T selectedValue;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  const IOSSegmentedControl({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.entries.map((entry) {
          final selected = entry.key == selectedValue;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!selected) {
                  IOSFeaturesService.selectionClick();
                  onChanged(entry.key);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding:
                    const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: selected
                      ? (isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected
                        ? AppColors.accent
                        : (isDark
                            ? AppColors.label3Dark
                            : AppColors.label3Light),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── iOS List Row ─────────────────────────────────────────────────────────────

class IOSListRow extends StatelessWidget {
  final IconData? leadingIcon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool isDestructive;

  const IOSListRow({
    super.key,
    this.leadingIcon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDestructive ? AppColors.danger : (iconColor ?? AppColors.accent);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap != null
            ? () {
                IOSFeaturesService.lightImpact();
                onTap!();
              }
            : null,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 11),
              child: Row(
                children: [
                  if (leadingIcon != null) ...[
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(leadingIcon,
                          color: color, size: 17),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: isDestructive
                                ? AppColors.danger
                                : null,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Text(subtitle!,
                              style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ] else if (onTap != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: isDark
                          ? AppColors.label3Dark
                          : AppColors.label3Light,
                    ),
                  ],
                ],
              ),
            ),
            if (showDivider)
              Divider(
                height: 0.5,
                indent: leadingIcon != null ? 62 : 16,
                color: isDark
                    ? AppColors.separatorDark
                    : AppColors.separatorLight,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── iOS Card ─────────────────────────────────────────────────────────────────

class IOSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const IOSCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card(isDark),
      ),
      child: child,
    );

    if (onTap == null) return card;

    return GestureDetector(
      onTap: () {
        IOSFeaturesService.lightImpact();
        onTap!();
      },
      child: card,
    );
  }
}

// ─── iOS Large Title App Bar ───────────────────────────────────────────────────

class IOSLargeTitleBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const IOSLargeTitleBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(title, style: theme.textTheme.headlineLarge),
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

// ─── Shimmer Loading Card ─────────────────────────────────────────────────────

class ShimmerCard extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const ShimmerCard({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1200.ms,
          color: isDark
              ? AppColors.surface3Dark.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.6),
        );
  }
}

// ─── Pulse Dot ───────────────────────────────────────────────────────────────

class PulseDot extends StatelessWidget {
  final Color color;
  final double size;

  const PulseDot({super.key, required this.color, this.size = 8});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 2.5,
      height: size * 2.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 2.5,
            height: size * 2.5,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(begin: 0.6, end: 1.0, duration: 1000.ms)
              .fade(begin: 0.8, end: 0.0, duration: 1000.ms),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── iOS Toggle Row ───────────────────────────────────────────────────────────

class IOSToggleRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final bool value;
  final ValueChanged<bool> onChanged;

  const IOSToggleRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return IOSListRow(
      leadingIcon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      onTap: null,
      trailing: CupertinoSwitch(
        value: value,
        onChanged: (v) {
          IOSFeaturesService.selectionClick();
          onChanged(v);
        },
        activeTrackColor: AppColors.accent,
      ),
    );
  }
}

// ─── Stats Summary Ring ───────────────────────────────────────────────────────

class ODCRingWidget extends StatelessWidget {
  final double percentage;
  final String centerText;
  final String centerSubtext;
  final Color color;
  final double size;
  final double strokeWidth;

  const ODCRingWidget({
    super.key,
    required this.percentage,
    required this.centerText,
    required this.centerSubtext,
    this.color = AppColors.accent,
    this.size = 140,
    this.strokeWidth = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background track
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation(
                isDark ? AppColors.surface2Dark : AppColors.surface2Light,
              ),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Progress arc
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (percentage / 100).clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (ctx, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: strokeWidth,
                valueColor: AlwaysStoppedAnimation(color),
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          // Center content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                centerText,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -1,
                ),
              ),
              Text(
                centerSubtext,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.label3Dark
                      : AppColors.label3Light,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Apple-style notification banner ──────────────────────────────────────────

class InAppNotificationBanner extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  final Color color;

  const InAppNotificationBanner({
    super.key,
    required this.title,
    required this.body,
    required this.icon,
    this.color = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.95)
            : AppColors.surfaceLight.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(body, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .slideY(begin: -1, end: 0, duration: 350.ms, curve: Curves.easeOut)
        .fade();
  }
}
