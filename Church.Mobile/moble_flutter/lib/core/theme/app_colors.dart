import 'package:flutter/material.dart';

/// Raw brand palette derived from the My Church design language.
///
/// These are low-level tokens. UI code should prefer [Theme.of(context)]
/// (ColorScheme) or the semantic [AppPalette] theme extension so that light
/// and dark modes resolve automatically.
class AppColors {
  AppColors._();

  // Primary — vivid royal blue used for CTAs and highlights.
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF60A5FA);

  // Navy — deep header backgrounds (dashboards, hero sections).
  static const Color navy = Color(0xFF1E3A5F);
  static const Color navyDeep = Color(0xFF12263F);

  // Warm accents — cream surfaces + gold highlights.
  static const Color gold = Color(0xFFC9A35B);
  static const Color cream = Color(0xFFEFE6D3);

  // Semantic status colors.
  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFE0982E);
  static const Color danger = Color(0xFFE5484D);
  static const Color info = Color(0xFF2563EB);

  // Neutrals (light).
  static const Color background = Color(0xFFF4F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF0F3F8);
  static const Color border = Color(0xFFE4E8F0);
  static const Color textPrimary = Color(0xFF161C27);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9AA3B2);

  // Neutrals (dark).
  static const Color darkBackground = Color(0xFF0E1622);
  static const Color darkSurface = Color(0xFF18212F);
  static const Color darkSurfaceAlt = Color(0xFF1F2A3A);
  static const Color darkBorder = Color(0xFF2A3546);
  static const Color darkTextPrimary = Color(0xFFE7ECF3);
  static const Color darkTextSecondary = Color(0xFF9BA6B6);

  static const Color onPrimary = Color(0xFFFFFFFF);
}
