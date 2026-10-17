import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/odc_session.dart';
import '../utils/date_utils.dart';
import '../theme/app_theme.dart';

class TimelineCard extends StatelessWidget {
  final TimelineEntry entry;
  final bool isLast;

  const TimelineCard({
    super.key,
    required this.entry,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconData = _getIconForType(entry.type);
    final color = _getColorForType(entry.type);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                iconData,
                color: color,
                size: 24,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withValues(alpha: 0.3),
                      color.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Timeline content
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getTitle(entry.type),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateTimeUtils.formatTime12Hour(entry.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  entry.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.2, end: 0);
  }

  IconData _getIconForType(TimelineEntryType type) {
    switch (type) {
      case TimelineEntryType.checkIn:
        return Icons.login_rounded;
      case TimelineEntryType.checkOut:
        return Icons.logout_rounded;
      case TimelineEntryType.breakStart:
        return Icons.pause_circle_rounded;
      case TimelineEntryType.breakEnd:
        return Icons.play_circle_rounded;
    }
  }

  Color _getColorForType(TimelineEntryType type) {
    switch (type) {
      case TimelineEntryType.checkIn:
        return AppTheme.successGreen;
      case TimelineEntryType.checkOut:
        return AppTheme.dangerRed;
      case TimelineEntryType.breakStart:
        return AppTheme.warningOrange;
      case TimelineEntryType.breakEnd:
        return AppTheme.primaryBlue;
    }
  }

  String _getTitle(TimelineEntryType type) {
    switch (type) {
      case TimelineEntryType.checkIn:
        return 'Checked In';
      case TimelineEntryType.checkOut:
        return 'Checked Out';
      case TimelineEntryType.breakStart:
        return 'Break Started';
      case TimelineEntryType.breakEnd:
        return 'Break Ended';
    }
  }
}
