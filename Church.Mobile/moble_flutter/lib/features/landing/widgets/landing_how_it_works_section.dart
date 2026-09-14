import 'package:flutter/material.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import 'landing_section.dart';

class LandingHowItWorksSection extends StatelessWidget {
  const LandingHowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 900 ? 5 : (width >= 560 ? 3 : 1);

    final steps = [
      ('01', l10n.landingHowStep1Title, l10n.landingHowStep1Body),
      ('02', l10n.landingHowStep2Title, l10n.landingHowStep2Body),
      ('03', l10n.landingHowStep3Title, l10n.landingHowStep3Body),
      ('04', l10n.landingHowStep4Title, l10n.landingHowStep4Body),
      ('05', l10n.landingHowStep5Title, l10n.landingHowStep5Body),
    ];

    return LandingSection(
      backgroundColor: palette.surfaceAlt,
      child: Column(
        children: [
          LandingSectionHeader(
            title: l10n.landingHowTitle,
            subtitle: l10n.landingHowSubtitle,
          ),
          const SizedBox(height: AppSpacing.xxl),
          LayoutBuilder(
            builder: (context, constraints) {
              final gap = AppSpacing.md;
              final cardWidth =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final step in steps)
                    SizedBox(
                      width: cardWidth,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: AppRadius.lgAll,
                          border: Border.all(color: palette.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.$1,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                step.$2,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                step.$3,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: palette.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
