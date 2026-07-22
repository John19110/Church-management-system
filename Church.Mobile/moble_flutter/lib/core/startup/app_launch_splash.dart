import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Branded splash: themed scaffold color, centered logo, progress indicator.
///
/// Native Android/iOS launch screens show the same background + logo so the
/// first OS frame already matches this widget (no blank/black window first).
class AppLaunchSplash extends StatelessWidget {
  const AppLaunchSplash({
    super.key,
    required this.isDark,
    this.opacity = 1,
  });

  final bool isDark;
  final double opacity;

  static const String logoAsset = 'assets/app_logo_splash.png';
  static const double logoWidthFraction = 0.28;
  static const double indicatorGap = 28;
  static const double indicatorSize = 28;

  Color get backgroundColor =>
      isDark ? AppColors.darkBackground : AppColors.background;

  Color get indicatorColor =>
      isDark ? AppColors.primaryLight : AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.maybeSizeOf(context) ?? _fallbackSize();
    final logoWidth = size.shortestSide * logoWidthFraction;
    final indicatorOffset = logoWidth / 2 + indicatorGap + indicatorSize / 2;

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: ColoredBox(
        color: backgroundColor,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              logoAsset,
              width: logoWidth,
              height: logoWidth,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            ),
            Transform.translate(
              offset: Offset(0, indicatorOffset),
              child: SizedBox(
                width: indicatorSize,
                height: indicatorSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: indicatorColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool resolveSplashIsDark(ThemeMode themeMode, Brightness platformBrightness) {
  // Instant splash defaults to light. Dark splash only for explicit app dark mode
  // (not system night mode).
  return themeMode == ThemeMode.dark;
}

Size _fallbackSize() {
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  return view.physicalSize / view.devicePixelRatio;
}
