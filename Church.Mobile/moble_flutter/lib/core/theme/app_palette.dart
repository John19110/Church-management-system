import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Semantic, theme-aware colors that aren't part of Material's [ColorScheme].
///
/// Access via `Theme.of(context).extension<AppPalette>()!` or the
/// `context.palette` helper below. Values resolve correctly for light/dark.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color navy;
  final Color gold;
  final Color cream;

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  // Soft tinted backgrounds for status chips.
  final Color successSoft;
  final Color warningSoft;
  final Color dangerSoft;
  final Color infoSoft;
  final Color neutralSoft;

  final Color border;
  final Color surfaceAlt;
  final Color textSecondary;
  final Color textTertiary;

  final List<Color> heroGradient;

  const AppPalette({
    required this.navy,
    required this.gold,
    required this.cream,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.successSoft,
    required this.warningSoft,
    required this.dangerSoft,
    required this.infoSoft,
    required this.neutralSoft,
    required this.border,
    required this.surfaceAlt,
    required this.textSecondary,
    required this.textTertiary,
    required this.heroGradient,
  });

  static const light = AppPalette(
    navy: AppColors.navy,
    gold: AppColors.gold,
    cream: AppColors.cream,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    info: AppColors.info,
    successSoft: Color(0xFFDDF3E4),
    warningSoft: Color(0xFFFBEBCF),
    dangerSoft: Color(0xFFFBE0E1),
    infoSoft: Color(0xFFDCE9FE),
    neutralSoft: Color(0xFFEDF0F5),
    border: AppColors.border,
    surfaceAlt: AppColors.surfaceAlt,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    heroGradient: [AppColors.navy, AppColors.navyDeep],
  );

  static const dark = AppPalette(
    navy: AppColors.navy,
    gold: AppColors.gold,
    cream: AppColors.cream,
    success: Color(0xFF3FBF77),
    warning: Color(0xFFECB44E),
    danger: Color(0xFFF06A6E),
    info: AppColors.primaryLight,
    successSoft: Color(0x333FBF77),
    warningSoft: Color(0x33ECB44E),
    dangerSoft: Color(0x33F06A6E),
    infoSoft: Color(0x3360A5FA),
    neutralSoft: Color(0xFF23303F),
    border: AppColors.darkBorder,
    surfaceAlt: AppColors.darkSurfaceAlt,
    textSecondary: AppColors.darkTextSecondary,
    textTertiary: Color(0xFF6B7688),
    heroGradient: [Color(0xFF1B3757), AppColors.navyDeep],
  );

  @override
  AppPalette copyWith({
    Color? navy,
    Color? gold,
    Color? cream,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? successSoft,
    Color? warningSoft,
    Color? dangerSoft,
    Color? infoSoft,
    Color? neutralSoft,
    Color? border,
    Color? surfaceAlt,
    Color? textSecondary,
    Color? textTertiary,
    List<Color>? heroGradient,
  }) {
    return AppPalette(
      navy: navy ?? this.navy,
      gold: gold ?? this.gold,
      cream: cream ?? this.cream,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      successSoft: successSoft ?? this.successSoft,
      warningSoft: warningSoft ?? this.warningSoft,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      infoSoft: infoSoft ?? this.infoSoft,
      neutralSoft: neutralSoft ?? this.neutralSoft,
      border: border ?? this.border,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      heroGradient: heroGradient ?? this.heroGradient,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      navy: Color.lerp(navy, other.navy, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      cream: Color.lerp(cream, other.cream, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      infoSoft: Color.lerp(infoSoft, other.infoSoft, t)!,
      neutralSoft: Color.lerp(neutralSoft, other.neutralSoft, t)!,
      border: Color.lerp(border, other.border, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      heroGradient: t < 0.5 ? heroGradient : other.heroGradient,
    );
  }
}

/// Convenience access to the semantic palette.
extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
