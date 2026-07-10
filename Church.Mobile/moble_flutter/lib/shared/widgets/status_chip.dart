import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';

enum StatusTone { success, warning, danger, info, neutral }

/// Small pill used to convey status (Active, On Leave, Pending, etc.).
///
/// Soft tinted background + strong foreground, matching the design language.
class StatusChip extends StatelessWidget {
  final String label;
  final StatusTone tone;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (bg, fg) = switch (tone) {
      StatusTone.success => (palette.successSoft, palette.success),
      StatusTone.warning => (palette.warningSoft, palette.warning),
      StatusTone.danger => (palette.dangerSoft, palette.danger),
      StatusTone.info => (palette.infoSoft, palette.info),
      StatusTone.neutral => (palette.neutralSoft, palette.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
