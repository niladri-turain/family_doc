import 'package:flutter/material.dart';

/// All colors used in the app. Never hard-code a Color in a screen —
/// always pick one from here so the theme stays consistent.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF4338CA);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primarySoft = Color(0xFFEEF0FF);
  static const Color primarySofter = Color(0xFFE0E3FF);

  // Surfaces
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF6F7FB);
  static const Color border = Color(0xFFE6E8F0);
  static const Color skeleton = Color(0xFFE6E8F0);
  static const Color skeletonLight = Color(0xFFEEF0F5);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF5B6478);
  static const Color textLabel = Color(0xFF334155);
  static const Color white = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF0F766E);
  static const Color error = Color(0xFFB91C1C);
  static const Color errorSoft = Color(0xFFFDECEC);
  static const Color errorSurface = Color(0xFFFFF5F5);
  static const Color errorBorder = Color(0xFFFBD5D5);
  static const Color errorText = Color(0xFF7F1D1D);

  // Document categories
  static const CategoryColor education =
      CategoryColor(Color(0xFF2563EB), Color(0xFFEAF1FF));
  static const CategoryColor government =
      CategoryColor(Color(0xFFC2410C), Color(0xFFFFF1E8));
  static const CategoryColor assets =
      CategoryColor(Color(0xFF0F766E), Color(0xFFE6F6F4));
  static const CategoryColor health =
      CategoryColor(Color(0xFFBE185D), Color(0xFFFDEBF3));
}

/// Foreground (icon / text) + soft background pair for a category.
class CategoryColor {
  const CategoryColor(this.foreground, this.background);

  final Color foreground;
  final Color background;
}
