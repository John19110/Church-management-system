import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import 'app_card.dart';

/// Reusable avatar + title/subtitle + trailing row, styled as a soft card.
///
/// Used for member/servant/classroom lists. The [leading] slot typically holds
/// an avatar; [trailing] a status chip or chevron.
class AppListRow extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  const AppListRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showChevron = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: palette.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.xs),
            trailing!,
          ],
          if (showChevron) ...[
            const SizedBox(width: AppSpacing.xxs),
            Icon(Icons.chevron_right, color: palette.textTertiary, size: 22),
          ],
        ],
      ),
    );
  }
}

/// Simple circular text/icon avatar with initials fallback.
class AppInitialsAvatar extends StatelessWidget {
  final String text;
  final double radius;
  final Color? color;

  const AppInitialsAvatar({
    super.key,
    required this.text,
    this.radius = 24,
    this.color,
  });

  String get _initials {
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final base = color ?? Theme.of(context).colorScheme.primary;
    return CircleAvatar(
      radius: radius,
      backgroundColor: base.withValues(alpha: 0.14),
      child: Text(
        _initials,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: base,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
