import 'package:flutter/material.dart';

import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_dimens.dart';

/// Centers [child] and caps its width on tablet/desktop.
class AppContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  const AppContent({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.contentMaxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          minHeight: 0,
        ),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: padding == null ? child : Padding(padding: padding!, child: child),
        ),
      ),
    );
  }
}

/// Standard page gutter that grows slightly on wide screens.
EdgeInsets appPagePadding(BuildContext context) {
  final horizontal = context.useRailNavigation ? AppSpacing.xl : AppSpacing.page;
  return EdgeInsets.fromLTRB(
    horizontal,
    AppSpacing.md,
    horizontal,
    AppSpacing.md,
  );
}
