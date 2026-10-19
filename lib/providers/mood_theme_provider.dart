import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mood_theme_model.dart';

/// Mood theme state
class MoodThemeState {
  final MoodTheme currentTheme;
  final bool autoModeEnabled;
  final List<MoodTheme> availableThemes;

  MoodThemeState({
    required this.currentTheme,
    required this.autoModeEnabled,
    required this.availableThemes,
  });

  MoodThemeState copyWith({
    MoodTheme? currentTheme,
    bool? autoModeEnabled,
    List<MoodTheme>? availableThemes,
  }) {
    return MoodThemeState(
      currentTheme: currentTheme ?? this.currentTheme,
      autoModeEnabled: autoModeEnabled ?? this.autoModeEnabled,
      availableThemes: availableThemes ?? this.availableThemes,
    );
  }
}

/// Mood theme notifier
class MoodThemeNotifier extends StateNotifier<MoodThemeState> {
  MoodThemeNotifier() : super(MoodThemeState(
    currentTheme: MoodThemes.neutral,
    autoModeEnabled: false,
    availableThemes: MoodThemes.getAllThemes(),
  )) {
    _loadSavedTheme();
  }

  static const String _themeKey = 'mood_theme';
  static const String _autoModeKey = 'auto_mode_enabled';

  /// Load saved theme from storage
  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMood = prefs.getString(_themeKey);
      final autoMode = prefs.getBool(_autoModeKey) ?? false;

      if (savedMood != null) {
        final moodType = MoodType.values.firstWhere(
          (m) => m.toString() == savedMood,
          orElse: () => MoodType.neutral,
        );
        state = state.copyWith(
          currentTheme: MoodThemes.getThemeByMood(moodType),
          autoModeEnabled: autoMode,
        );
      }

      // If auto mode is enabled, update theme based on time
      if (autoMode) {
        _updateAutoTheme();
      }
    } catch (e) {
      print('Error loading saved theme: $e');
    }
  }

  /// Change mood theme
  Future<void> changeMood(MoodType mood) async {
    try {
      final newTheme = MoodThemes.getThemeByMood(mood);
      state = state.copyWith(currentTheme: newTheme);

      // Save to storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mood.toString());
      
      // Disable auto mode when manually changing
      if (state.autoModeEnabled) {
        await toggleAutoMode();
      }
    } catch (e) {
      print('Error changing mood: $e');
    }
  }

  /// Toggle auto mode (automatically change theme based on time/day)
  Future<void> toggleAutoMode() async {
    try {
      final newAutoMode = !state.autoModeEnabled;
      state = state.copyWith(autoModeEnabled: newAutoMode);

      // Save to storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoModeKey, newAutoMode);

      // Update theme if auto mode is enabled
      if (newAutoMode) {
        _updateAutoTheme();
      }
    } catch (e) {
      print('Error toggling auto mode: $e');
    }
  }

  /// Update theme based on time of day
  void _updateAutoTheme() {
    final detectedMood = MoodThemes.detectMoodByTime();
    final newTheme = MoodThemes.getThemeByMood(detectedMood);
    state = state.copyWith(currentTheme: newTheme);
  }

  /// Check and update theme if auto mode is enabled
  Future<void> checkAndUpdateAutoTheme() async {
    if (state.autoModeEnabled) {
      _updateAutoTheme();
    }
  }

  /// Get current mood type
  MoodType get currentMood => state.currentTheme.mood;

  /// Get current primary color
  get primaryColor => state.currentTheme.primaryColor;

  /// Get current accent color
  get accentColor => state.currentTheme.accentColor;

  /// Get current gradient
  get gradient => state.currentTheme.gradient;
}

/// Mood theme provider
final moodThemeProvider = StateNotifierProvider<MoodThemeNotifier, MoodThemeState>((ref) {
  return MoodThemeNotifier();
});

/// Quick access to current theme
final currentMoodThemeProvider = Provider<MoodTheme>((ref) {
  return ref.watch(moodThemeProvider).currentTheme;
});

/// Quick access to theme data
final themeDataProvider = Provider((ref) {
  final moodTheme = ref.watch(currentMoodThemeProvider);
  return moodTheme.toThemeData();
});
