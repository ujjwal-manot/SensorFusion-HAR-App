import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._();

  // ── Core Colors ──────────────────────────────────────────────────────
  static const background = Color(0xFF050508);
  static const surface = Color(0xFF0F1115);
  static const cardColor = Color(0xFF161922);
  static const borderColor = Color(0x14FFFFFF);
  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF94A3B8);
  static const textTertiary = Color(0xFF475569);
  static const accent = Color(0xFF06B6D4);
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);

  // ── Activity Gradients ───────────────────────────────────────────────
  static const stationaryGradient = [Color(0xFF10B981), Color(0xFF059669)];
  static const locomotionGradient = [Color(0xFF3B82F6), Color(0xFF2563EB)];
  static const vehicleGradient = [Color(0xFFF59E0B), Color(0xFFD97706)];
  static const gestureGradient = [Color(0xFF8B5CF6), Color(0xFF7C3AED)];

  // ── Accent Gradient ──────────────────────────────────────────────────
  static const accentGradient = [Color(0xFF06B6D4), Color(0xFF0891B2)];

  // ── Glow Colors ──────────────────────────────────────────────────────
  static const stationaryGlow = Color(0xFF10B981);
  static const locomotionGlow = Color(0xFF3B82F6);
  static const vehicleGlow = Color(0xFFF59E0B);
  static const gestureGlow = Color(0xFF8B5CF6);

  /// Returns the gradient pair for a macro activity category.
  static List<Color> gradientForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'stationary':
        return stationaryGradient;
      case 'locomotion':
        return locomotionGradient;
      case 'vehicle':
        return vehicleGradient;
      case 'gesture':
        return gestureGradient;
      default:
        return [textSecondary, textTertiary];
    }
  }

  /// Returns the primary (first) color of the activity gradient.
  static Color primaryForCategory(String category) {
    return gradientForCategory(category).first;
  }

  /// Returns an icon for a macro activity.
  static IconData iconForActivity(String activity) {
    switch (activity.toLowerCase()) {
      case 'stationary':
        return Icons.self_improvement;
      case 'locomotion':
        return Icons.directions_run;
      case 'vehicle':
        return Icons.commute;
      case 'gesture':
        return Icons.touch_app;
      default:
        return Icons.sensors;
    }
  }

  /// Apply system chrome settings (status bar, nav bar).
  static void applySystemChrome() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  // ── ThemeData ────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        canvasColor: background,
        colorScheme: const ColorScheme.dark(
          surface: surface,
          primary: accent,
          onPrimary: Colors.white,
          secondary: accent,
          error: error,
        ),
        fontFamily: 'SF Pro Display',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textSecondary,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: textTertiary,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: 0.5,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        cardTheme: CardTheme(
          color: cardColor,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: borderColor),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: error, width: 1.5),
          ),
          hintStyle: const TextStyle(color: textTertiary),
          labelStyle: const TextStyle(color: textSecondary),
          prefixIconColor: textTertiary,
        ),
        dividerTheme: const DividerThemeData(
          color: borderColor,
          thickness: 1,
        ),
        splashFactory: InkSparkle.splashFactory,
      );
}
