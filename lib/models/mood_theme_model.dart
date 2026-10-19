import 'package:flutter/material.dart';

/// Mood types for dynamic theming
enum MoodType {
  energetic,    // High energy, productive
  calm,         // Peaceful, focused
  motivated,    // Goal-oriented, driven
  creative,     // Innovative, inspired
  tired,        // Low energy, need rest
  stressed,     // Overwhelmed, anxious
  happy,        // Joyful, content
  neutral,      // Default, balanced
}

/// Mood theme configuration
class MoodTheme {
  final MoodType mood;
  final String name;
  final String description;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Color secondaryTextColor;
  final LinearGradient gradient;
  final String emoji;

  const MoodTheme({
    required this.mood,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.gradient,
    required this.emoji,
  });

  /// Get theme data for Flutter
  ThemeData toThemeData() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        background: backgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textColor,
        onBackground: textColor,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        displaySmall: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        headlineMedium: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: textColor),
        titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: secondaryTextColor),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: surfaceColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }
}

/// Predefined mood themes
class MoodThemes {
  static const energetic = MoodTheme(
    mood: MoodType.energetic,
    name: 'Energetic',
    description: 'High energy and productive',
    emoji: '⚡',
    primaryColor: Color(0xFFFF6B35),    // Vibrant orange
    accentColor: Color(0xFFFFB800),     // Golden yellow
    backgroundColor: Color(0xFF0A0A0A),
    surfaceColor: Color(0xFF1A1A1A),
    textColor: Color(0xFFFFFFFF),
    secondaryTextColor: Color(0xFFB0B0B0),
    gradient: LinearGradient(
      colors: [Color(0xFFFF6B35), Color(0xFFFFB800)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const calm = MoodTheme(
    mood: MoodType.calm,
    name: 'Calm',
    description: 'Peaceful and focused',
    emoji: '🌊',
    primaryColor: Color(0xFF4A90E2),    // Soft blue
    accentColor: Color(0xFF50C9CE),     // Teal
    backgroundColor: Color(0xFF0A0A0A),
    surfaceColor: Color(0xFF141414),
    textColor: Color(0xFFFFFFFF),
    secondaryTextColor: Color(0xFFB0B0B0),
    gradient: LinearGradient(
      colors: [Color(0xFF4A90E2), Color(0xFF50C9CE)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const motivated = MoodTheme(
    mood: MoodType.motivated,
    name: 'Motivated',
    description: 'Goal-oriented and driven',
    emoji: '🚀',
    primaryColor: Color(0xFF9B59B6),    // Purple
    accentColor: Color(0xFFE74C3C),     // Red
    backgroundColor: Color(0xFF0A0A0A),
    surfaceColor: Color(0xFF1A1A1A),
    textColor: Color(0xFFFFFFFF),
    secondaryTextColor: Color(0xFFB0B0B0),
    gradient: LinearGradient(
      colors: [Color(0xFF9B59B6), Color(0xFFE74C3C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const creative = MoodTheme(
    mood: MoodType.creative,
    name: 'Creative',
    description: 'Innovative and inspired',
    emoji: '🎨',
    primaryColor: Color(0xFFE91E63),    // Pink
    accentColor: Color(0xFF9C27B0),     // Deep purple
    backgroundColor: Color(0xFF0A0A0A),
    surfaceColor: Color(0xFF1A1A1A),
    textColor: Color(0xFFFFFFFF),
    secondaryTextColor: Color(0xFFB0B0B0),
    gradient: LinearGradient(
      colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const tired = MoodTheme(
    mood: MoodType.tired,
    name: 'Tired',
    description: 'Low energy, need rest',
    emoji: '😴',
    primaryColor: Color(0xFF607D8B),    // Blue grey
    accentColor: Color(0xFF90A4AE),     // Light blue grey
    backgroundColor: Color(0xFF0A0A0A),
    surfaceColor: Color(0xFF121212),
    textColor: Color(0xFFE0E0E0),
    secondaryTextColor: Color(0xFF909090),
    gradient: LinearGradient(
      colors: [Color(0xFF607D8B), Color(0xFF90A4AE)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const stressed = MoodTheme(
    mood: MoodType.stressed,
    name: 'Stressed',
    description: 'Overwhelmed, need calm',
    emoji: '😰',
    primaryColor: Color(0xFFFF5722),    // Deep orange
    accentColor: Color(0xFFFF9800),     // Orange
    backgroundColor: Color(0xFF0A0A0A),
    surfaceColor: Color(0xFF1A1A1A),
    textColor: Color(0xFFFFFFFF),
    secondaryTextColor: Color(0xFFB0B0B0),
    gradient: LinearGradient(
      colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const happy = MoodTheme(
    mood: MoodType.happy,
    name: 'Happy',
    description: 'Joyful and content',
    emoji: '😊',
    primaryColor: Color(0xFFFFEB3B),    // Yellow
    accentColor: Color(0xFFFF9800),     // Orange
    backgroundColor: Color(0xFF0A0A0A),
    surfaceColor: Color(0xFF1A1A1A),
    textColor: Color(0xFFFFFFFF),
    secondaryTextColor: Color(0xFFB0B0B0),
    gradient: LinearGradient(
      colors: [Color(0xFFFFEB3B), Color(0xFFFF9800)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const neutral = MoodTheme(
    mood: MoodType.neutral,
    name: 'Neutral',
    description: 'Balanced and default',
    emoji: '😐',
    primaryColor: Color(0xFF4F6EF7),    // Blue (default)
    accentColor: Color(0xFF6C8FFF),     // Light blue
    backgroundColor: Color(0xFF000000),
    surfaceColor: Color(0xFF1E1E1E),
    textColor: Color(0xFFFFFFFF),
    secondaryTextColor: Color(0xFFB0B0B0),
    gradient: LinearGradient(
      colors: [Color(0xFF4F6EF7), Color(0xFF6C8FFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  /// Get all mood themes
  static List<MoodTheme> getAllThemes() {
    return [
      energetic,
      calm,
      motivated,
      creative,
      happy,
      neutral,
      tired,
      stressed,
    ];
  }

  /// Get theme by mood type
  static MoodTheme getThemeByMood(MoodType mood) {
    switch (mood) {
      case MoodType.energetic:
        return energetic;
      case MoodType.calm:
        return calm;
      case MoodType.motivated:
        return motivated;
      case MoodType.creative:
        return creative;
      case MoodType.tired:
        return tired;
      case MoodType.stressed:
        return stressed;
      case MoodType.happy:
        return happy;
      case MoodType.neutral:
        return neutral;
    }
  }

  /// Auto-detect mood based on time of day
  static MoodType detectMoodByTime() {
    final hour = DateTime.now().hour;
    
    if (hour >= 6 && hour < 9) {
      return MoodType.energetic;    // Morning: energetic
    } else if (hour >= 9 && hour < 12) {
      return MoodType.motivated;    // Mid-morning: motivated
    } else if (hour >= 12 && hour < 14) {
      return MoodType.calm;         // Lunch: calm
    } else if (hour >= 14 && hour < 17) {
      return MoodType.creative;     // Afternoon: creative
    } else if (hour >= 17 && hour < 20) {
      return MoodType.happy;        // Evening: happy
    } else if (hour >= 20 && hour < 22) {
      return MoodType.calm;         // Night: calm
    } else {
      return MoodType.tired;        // Late night: tired
    }
  }

  /// Auto-detect mood based on day of week
  static MoodType detectMoodByDay() {
    final day = DateTime.now().weekday;
    
    switch (day) {
      case DateTime.monday:
        return MoodType.motivated;    // Monday: motivated
      case DateTime.tuesday:
      case DateTime.wednesday:
        return MoodType.creative;     // Mid-week: creative
      case DateTime.thursday:
        return MoodType.energetic;    // Thursday: energetic
      case DateTime.friday:
        return MoodType.happy;        // Friday: happy
      case DateTime.saturday:
      case DateTime.sunday:
        return MoodType.calm;         // Weekend: calm
      default:
        return MoodType.neutral;
    }
  }
}
