import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../landing_external_links.dart';
import 'landing_contact_section.dart';
import 'landing_section.dart';

class LandingFooter extends StatelessWidget {
  const LandingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final year = DateTime.now().year;
    final privacyUrl = '${AppConstants.baseUrl}/privacy-policy';
    final deletionUrl = '${AppConstants.baseUrl}/account-deletion';

    return ColoredBox(
      color: AppColors.navyDeep,
      child: LandingSection(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.appTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.landingFooterTagline,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: [
                _FooterLink(
                  label: l10n.login,
                  onTap: () => context.go(AppRoutes.login),
                ),
                _FooterLink(
                  label: l10n.register,
                  onTap: () => context.go(AppRoutes.register),
                ),
                _FooterLink(
                  label: l10n.landingContactTitle,
                  onTap: () => openExternalUrl('mailto:${LandingContactSection.email}'),
                ),
                _FooterLink(
                  label: l10n.landingPrivacyPolicy,
                  onTap: () => openExternalUrl(privacyUrl),
                ),
                _FooterLink(
                  label: l10n.landingAccountDeletion,
                  onTap: () => openExternalUrl(deletionUrl),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '${l10n.landingContactPhone}: ${LandingContactSection.phone}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
            Text(
              '${l10n.landingContactEmail}: ${LandingContactSection.email}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.landingFooterCopyright(year),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }
}
