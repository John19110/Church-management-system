import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';

enum AppButtonVariant { primary, secondary, tonal, danger }

enum AppButtonSize { regular, compact }

/// Unified button used across the app.
///
/// Wraps the themed [ElevatedButton]/[OutlinedButton] so every CTA shares the
/// same height, radius, loading behaviour and icon spacing.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.regular,
    this.icon,
    this.loading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.secondary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = size == AppButtonSize.regular ? 52.0 : 44.0;
    final minSize = Size(expand ? double.infinity : 0, height);
    final effectiveOnPressed = loading ? null : onPressed;

    final child = loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation(
                variant == AppButtonVariant.secondary
                    ? scheme.primary
                    : scheme.onPrimary,
              ),
            ),
          )
        : _content();

    switch (variant) {
      case AppButtonVariant.secondary:
        return OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(minimumSize: minSize),
          child: child,
        );
      case AppButtonVariant.tonal:
        return FilledButton.tonal(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            minimumSize: minSize,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
          child: child,
        );
      case AppButtonVariant.danger:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
            minimumSize: minSize,
          ),
          child: child,
        );
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(minimumSize: minSize),
          child: child,
        );
    }
  }

  Widget _content() {
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
