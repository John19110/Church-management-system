import 'package:flutter/material.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import 'landing_section.dart';

class LandingFeaturesSection extends StatelessWidget {
  const LandingFeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1000 ? 3 : (width >= 680 ? 2 : 1);

    final items = <(IconData, String, String)>[
      (Icons.home_work_outlined, l10n.landingFeatureChurchTitle, l10n.landingFeatureChurchBody),
      (Icons.groups_outlined, l10n.landingFeaturePeopleTitle, l10n.landingFeaturePeopleBody),
      (Icons.event_available_outlined, l10n.landingFeatureAttendanceTitle, l10n.landingFeatureAttendanceBody),
      (Icons.class_outlined, l10n.landingFeatureClassroomsTitle, l10n.landingFeatureClassroomsBody),
      (Icons.tune_outlined, l10n.landingFeatureCustomFieldsTitle, l10n.landingFeatureCustomFieldsBody),
      (Icons.verified_user_outlined, l10n.landingFeatureRolesTitle, l10n.landingFeatureRolesBody),
      (Icons.apartment_outlined, l10n.landingFeatureTenantTitle, l10n.landingFeatureTenantBody),
      (Icons.notifications_outlined, l10n.landingFeatureNotificationsTitle, l10n.landingFeatureNotificationsBody),
    ];

    return LandingSection(
      backgroundColor: palette.surfaceAlt,
      child: Column(
        children: [
          LandingSectionHeader(
            title: l10n.landingFeaturesTitle,
            subtitle: l10n.landingFeaturesSubtitle,
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
                  for (final item in items)
                    SizedBox(
                      width: cardWidth,
                      child: LandingFeatureCard(
                        icon: item.$1,
                        title: item.$2,
                        description: item.$3,
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
