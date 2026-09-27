import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../widgets/customization_language_card.dart';

class CustomizationHubScreen extends ConsumerWidget {
  const CustomizationHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final canManage = AuthRoleUtils.canManageCustomFields(role);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.customization)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            l10n.customizeYourChurch,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.customizationIntro),
          const SizedBox(height: AppSpacing.lg),
          const CustomizationLanguageCard(),
          if (canManage) ...[
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: ListTile(
                leading: const Icon(Icons.public),
                title: Text(l10n.churchLanguages),
                subtitle: Text(l10n.churchLanguagesDescription),
                trailing: AppIcons.chevronForward(context),
                onTap: () => context.push(AppRoutes.churchLanguages),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: ListTile(
                leading: const Icon(Icons.tune),
                title: Text(l10n.customFields),
                subtitle: Text(l10n.customFieldsLanding),
                trailing: AppIcons.chevronForward(context),
                onTap: () => context.push(AppRoutes.customFieldsHub),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: ListTile(
                leading: const Icon(Icons.extension_outlined),
                title: Text(l10n.customFeatures),
                subtitle: Text(l10n.customFeaturesLanding),
                trailing: AppIcons.chevronForward(context),
                onTap: () => context.push(AppRoutes.customFeaturesHub),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
