import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// The big check-in/break/checkout button.
/// [label] and [color] are passed directly so the caller controls semantics.
class PremiumActionButton extends StatelessWidget {
  final bool isActive;           // true = "active/danger" gradient
  final String activeText;       // text when isActive == true
  final String inactiveText;     // text when isActive == false
  final VoidCallback onPressed;

  const PremiumActionButton({
    super.key,
    required this.isActive,
    required this.onPressed,
    this.activeText = "I'M OUT",
    this.inactiveText = "I'M IN",
  });

  @override
  Widget build(BuildContext context) {
    final List<Color> gradientColors = isActive
        ? [Colors.red.shade400, Colors.red.shade600]
        : [Colors.green.shade400, Colors.green.shade600];
    final shadowColor = isActive ? Colors.red : Colors.green;
    final icon = isActive ? Icons.logout_rounded : Icons.login_rounded;
    final label = isActive ? activeText : inactiveText;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(
            duration: 2400.ms,
            color: Colors.white.withValues(alpha: 0.25),
          )
          .animate()
          .scale(duration: 300.ms, curve: Curves.easeInOut),
    );
  }
}

class SecondaryActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const SecondaryActionButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: buttonColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: buttonColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: buttonColor, size: 20),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: buttonColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
