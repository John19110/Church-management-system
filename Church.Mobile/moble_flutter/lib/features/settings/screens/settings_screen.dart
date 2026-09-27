import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/widgets/delete_account_section.dart';
import '../widgets/application_language_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.appSettings,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          const ApplicationLanguageCard(),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: ListTile(
              leading: const Icon(Icons.tune),
              title: Text(l10n.customization),
              subtitle: Text(l10n.customizeYourChurch),
              trailing: AppIcons.chevronForward(context),
              onTap: () => context.push(AppRoutes.customization),
            ),
          ),
          if (role == 'superadmin') ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.table_view_outlined),
                title: Text(l10n.memberExcelChurchTitle),
                subtitle: Text(l10n.memberExcelSettingsTile),
                trailing: AppIcons.chevronForward(context),
                onTap: () => context.push(AppRoutes.churchMembersExcel),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.accountSection,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.dangerZone,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const DeleteAccountSection(),
        ],
      ),
    );
  }
}
