import 'package:flutter/material.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class AppColors {
  // Accent — a single calm indigo/blue
  static const Color accent = Color(0xFF4F6EF7);
  static const Color accentLight = Color(0xFFEEF1FF);
  static const Color accentDark = Color(0xFF3A56D4);

  // Semantic
  static const Color success = Color(0xFF34C759); // iOS green
  static const Color warning = Color(0xFFFF9500); // iOS orange
  static const Color danger = Color(0xFFFF3B30);  // iOS red
  static const Color info = Color(0xFF007AFF);    // iOS blue

  // Neutral — light
  static const Color bgLight = Color(0xFFF2F2F7); // iOS grouped bg
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surface2Light = Color(0xFFF2F2F7);
  static const Color surface3Light = Color(0xFFE5E5EA);
  static const Color labelLight = Color(0xFF000000);
  static const Color label2Light = Color(0xFF3C3C43);
  static const Color label3Light = Color(0xFF6D6D72);
  static const Color separatorLight = Color(0xFFC6C6C8);

  // Neutral — dark
  static const Color bgDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color surface2Dark = Color(0xFF2C2C2E);
  static const Color surface3Dark = Color(0xFF3A3A3C);
  static const Color labelDark = Color(0xFFFFFFFF);
  static const Color label2Dark = Color(0xFFEBEBF5);
  static const Color label3Dark = Color(0xFF98989F);
  static const Color separatorDark = Color(0xFF38383A);

  // Keep legacy names for backward compat with old screens
  static const Color primaryBlue = accent;
  static const Color successGreen = success;
  static const Color warningOrange = warning;
  static const Color dangerRed = danger;
  static const Color lightBackground = bgLight;
  static const Color darkBackground = bgDark;
}

// ─── Spacing ─────────────────────────────────────────────────────────────────
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

// ─── Radius ──────────────────────────────────────────────────────────────────
class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius button = BorderRadius.all(Radius.circular(md));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(sm));
}

// ─── Shadows ─────────────────────────────────────────────────────────────────
class AppShadows {
  static List<BoxShadow> card(bool isDark) => isDark
      ? []
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ];

  static List<BoxShadow> elevated(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}

// ─── App Theme ────────────────────────────────────────────────────────────────
class AppTheme {
  // Legacy statics for backward compat
  static const Color primaryBlue = AppColors.accent;
  static const Color successGreen = AppColors.success;
  static const Color warningOrange = AppColors.warning;
  static const Color dangerRed = AppColors.danger;
  static const Color lightBackground = AppColors.bgLight;
  static const Color darkBackground = AppColors.bgDark;

  static ThemeData lightTheme = _build(Brightness.light);
  static ThemeData darkTheme = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final onSurface = isDark ? AppColors.labelDark : AppColors.labelLight;

    final cs = ColorScheme(
      brightness: brightness,
      primary: AppColors.accent,
      onPrimary: Colors.white,
      primaryContainer: isDark
          ? AppColors.accent.withValues(alpha: 0.2)
          : AppColors.accentLight,
      onPrimaryContainer: AppColors.accent,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      secondaryContainer: isDark
          ? AppColors.surface3Dark
          : AppColors.surface3Light,
      onSecondaryContainer: onSurface,
      tertiary: AppColors.success,
      onTertiary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
      outline: isDark ? AppColors.separatorDark : AppColors.separatorLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      scaffoldBackgroundColor: bg,

      // ── App Bar ─────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),

      // ── Cards ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
        margin: EdgeInsets.zero,
      ),

      // ── Navigation Bar (Material 3) ───────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.accent.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            );
          }
          return TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: isDark ? AppColors.label3Dark : AppColors.label3Light,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.accent, size: 24);
          }
          return IconThemeData(
            color: isDark ? AppColors.label3Dark : AppColors.label3Light,
            size: 24,
          );
        }),
      ),

      // ── Inputs ───────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(
          color: isDark ? AppColors.label3Dark : AppColors.label3Light,
          fontWeight: FontWeight.w400,
        ),
      ),

      // ── Elevated Button ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),

      // ── Text ─────────────────────────────────────────────────────────────
      textTheme: TextTheme(
        // Large display numbers
        displayLarge: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: -2,
          height: 1.0,
        ),
        displayMedium: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: -1.5,
          height: 1.05,
        ),
        displaySmall: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: -1,
          height: 1.1,
        ),
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: -0.5,
          height: 1.15,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: onSurface,
          letterSpacing: -0.3,
          height: 1.2,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
          letterSpacing: -0.2,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: onSurface,
          letterSpacing: -0.1,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: onSurface,
          letterSpacing: 0,
          height: 1.35,
        ),
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: onSurface,
          letterSpacing: 0,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: onSurface,
          letterSpacing: 0,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: onSurface,
          letterSpacing: 0,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: isDark ? AppColors.label2Dark : AppColors.label2Light,
          letterSpacing: 0,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: onSurface,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.label3Dark : AppColors.label3Light,
          letterSpacing: 0.3,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.label3Dark : AppColors.label3Light,
          letterSpacing: 0.4,
        ),
      ),

      // ── Chips ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:
            isDark ? AppColors.surface2Dark : AppColors.surface2Light,
        selectedColor: AppColors.accent.withValues(alpha: 0.15),
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.chip),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.label2Dark : AppColors.label2Light,
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.separatorDark : AppColors.separatorLight,
        thickness: 0.5,
        space: 0,
      ),
    );
  }
}
