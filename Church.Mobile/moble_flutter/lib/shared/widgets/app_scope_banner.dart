import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';

/// Explains the current list/filter scope so users do not misread the data.
class AppScopeBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;
  final Color? background;

  const AppScopeBanner({
    super.key,
    required this.message,
    this.icon = Icons.filter_list,
    this.color,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fg = color ?? palette.info;
    final bg = background ?? palette.infoSoft;

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.mdAll,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
