import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import 'landing_section.dart';

class LandingRegistrationProcessSection extends StatelessWidget {
  const LandingRegistrationProcessSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = context.palette;
    final scheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 800;

    final steps = [
      l10n.landingRegStep1,
      l10n.landingRegStep2,
      l10n.landingRegStep3,
      l10n.landingRegStep4,
      l10n.landingRegStep5,
      l10n.landingRegStep6,
      l10n.landingRegStep7,
    ];

    return LandingSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LandingSectionHeader(
            title: l10n.landingRegistrationTitle,
            subtitle: l10n.landingRegistrationSubtitle,
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (narrow)
            Column(
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  _FlowStep(index: i + 1, text: steps[i]),
                  if (i < steps.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Icon(Icons.arrow_downward, color: scheme.primary),
                    ),
                ],
              ],
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  _FlowStep(index: i + 1, text: steps[i]),
                  if (i < steps.length - 1)
                    Icon(
                      Icons.arrow_forward,
                      color: scheme.primary.withValues(alpha: 0.7),
                      size: 20,
                    ),
                ],
              ],
            ),
          const SizedBox(height: AppSpacing.xxl),
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.surfaceAlt,
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: palette.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.landingRegChurchPathTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.landingRegChurchPathBody,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.textSecondary,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.landingRegMeetingPathTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.landingRegMeetingPathBody,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.textSecondary,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final scheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 160, minWidth: 120),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: palette.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: scheme.primary,
                child: Text(
                  '$index',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                text,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
