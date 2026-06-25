import 'package:flutter/material.dart';

/// Centralized colors and styling for the car launcher.
///
/// The palette is intentionally dark with high-contrast accents so the UI stays
/// readable on a sunlit head unit while driving.
class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFF0B0F17);
  static const Color surface = Color(0xFF161C28);
  static const Color surfaceHigh = Color(0xFF1F2735);
  static const Color accent = Color(0xFF3DDC97);
  static const Color accentAlt = Color(0xFF4DA3FF);
  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFF9AA5B1);

  static const double radius = 24;

  static ThemeData build() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        surface: surface,
        primary: accent,
        secondary: accentAlt,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
    );
  }

  /// Standard card decoration used by every dashboard block.
  static BoxDecoration cardDecoration({Color? color}) {
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
    );
  }
}
