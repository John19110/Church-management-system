import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import 'app_button.dart';

/// A full-page loading indicator.
class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 34,
            width: 34,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.palette.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// A reusable "pill" icon badge inside a soft tinted circle.
class SoftIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  const SoftIconBadge({
    super.key,
    required this.icon,
    required this.color,
    required this.background,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.44, color: color),
    );
  }
}

/// A full-page error state with optional retry.
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SoftIconBadge(
                    icon: Icons.error_outline_rounded,
                    color: palette.danger,
                    background: palette.dangerSoft,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SelectableText(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: l10n.retry,
                      icon: Icons.refresh,
                      expand: false,
                      onPressed: onRetry,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A full-page empty state.
class EmptyWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyWidget({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SoftIconBadge(
              icon: icon,
              color: palette.textTertiary,
              background: palette.neutralSoft,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: palette.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: actionLabel!,
                expand: false,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows a snackbar with an error message.
void showErrorSnackbar(BuildContext context, String message) {
  showErrorSnackbarFixed(context, message);
}

/// Shows a snackbar with a success message.
void showSuccessSnackbar(BuildContext context, String message) {
  showSuccessSnackbarFixed(context, message);
}

void showErrorSnackbarFixed(BuildContext context, String message) {
  _showSnackbar(
    context,
    message,
    background: AppColors.danger,
    icon: Icons.error_outline_rounded,
  );
}

void showSuccessSnackbarFixed(BuildContext context, String message) {
  _showSnackbar(
    context,
    message,
    background: AppColors.success,
    icon: Icons.check_circle_outline_rounded,
  );
}

void _showSnackbar(
  BuildContext context,
  String message, {
  required Color background,
  required IconData icon,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: background,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Shows a confirmation dialog. Returns true if confirmed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String? confirmText,
  Color confirmColor = AppColors.danger,
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirmText ?? l10n.delete,
            style: TextStyle(color: confirmColor),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
