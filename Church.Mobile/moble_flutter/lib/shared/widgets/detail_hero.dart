import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import 'app_network_avatar.dart';

/// Premium gradient hero banner for detail screens.
///
/// Shows a large avatar (photo or initials) over a navy gradient, with a title,
/// optional eyebrow/subtitle and a wrap of contextual [chips].
class DetailHero extends StatelessWidget {
  final String title;
  final String initials;
  final String? imageUrl;
  final String? eyebrow;
  final String? subtitle;
  final List<Widget> chips;
  final String? debugTag;

  const DetailHero({
    super.key,
    required this.title,
    required this.initials,
    this.imageUrl,
    this.eyebrow,
    this.subtitle,
    this.chips = const [],
    this.debugTag,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.heroGradient,
        ),
        borderRadius: AppRadius.xlAll,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
            ),
            child: AppNetworkAvatar(
              imageUrl: imageUrl,
              debugTag: debugTag,
              radius: 46,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              placeholder: Text(
                initials,
                style: textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (eyebrow != null) ...[
            Text(
              eyebrow!.toUpperCase(),
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
          if (chips.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              alignment: WrapAlignment.center,
              children: chips,
            ),
          ],
        ],
      ),
    );
  }
}

/// Small translucent chip used inside [DetailHero] (e.g. status, category).
class HeroChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  const HeroChip({super.key, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
