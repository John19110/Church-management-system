import 'package:flutter/material.dart';

/// Window-size breakpoints used for adaptive layout and navigation.
///
/// Values follow Material guidance (compact / medium / expanded).
class AppBreakpoints {
  AppBreakpoints._();

  static const double compact = 600;
  static const double medium = 840;
  static const double expanded = 1200;

  /// Comfortable reading width for lists and forms on large screens.
  static const double contentMaxWidth = 1040;

  /// Narrow column for auth and short forms.
  static const double formMaxWidth = 480;
}

enum AppWindowSize { compact, medium, expanded }

extension AppLayoutX on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);

  double get screenWidth => screenSize.width;

  AppWindowSize get windowSize {
    final width = screenWidth;
    if (width >= AppBreakpoints.expanded) return AppWindowSize.expanded;
    if (width >= AppBreakpoints.medium) return AppWindowSize.medium;
    return AppWindowSize.compact;
  }

  bool get isCompact => windowSize == AppWindowSize.compact;

  bool get isMedium => windowSize == AppWindowSize.medium;

  bool get isExpanded => windowSize == AppWindowSize.expanded;

  /// Persistent side navigation instead of a bottom bar.
  bool get useRailNavigation => screenWidth >= AppBreakpoints.medium;

  bool get useExtendedRail => screenWidth >= AppBreakpoints.expanded;

  int gridCrossAxisCount({int compact = 1, int medium = 2, int expanded = 3}) {
    return switch (windowSize) {
      AppWindowSize.compact => compact,
      AppWindowSize.medium => medium,
      AppWindowSize.expanded => expanded,
    };
  }
}
