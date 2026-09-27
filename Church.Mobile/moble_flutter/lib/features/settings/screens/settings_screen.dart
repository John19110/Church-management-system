import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/organization_languages.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../models/language_settings.dart';
import '../providers/language_settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final canManage = AuthRoleUtils.canManageCustomFields(role);
    final locale = ref.watch(localeProvider);
    final church = ref.watch(churchLanguagesProvider).valueOrNull ??
        ChurchLanguages.bilingual();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final supported = church.supportedLanguages;

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
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                  ),
                  title: Text(isDark ? l10n.darkMode : l10n.lightMode),
                  value: isDark,
                  onChanged: (_) =>
                      ref.read(themeModeProvider.notifier).toggle(),
                ),
                const Divider(height: 0),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(l10n.appLanguage),
                  ),
                ),
                for (final code in supported)
                  RadioListTile<String>(
                    value: code,
                    groupValue: locale.languageCode,
                    title: Text(
                      code == OrganizationLanguages.arabic
                          ? l10n.arabic
                          : l10n.english,
                    ),
                    onChanged: (value) => _changeLanguage(context, ref, value),
                  ),
              ],
            ),
          ),
          if (canManage) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.translate),
                title: Text(l10n.churchLanguages),
                subtitle: Text(l10n.churchLanguagesDescription),
                trailing: AppIcons.chevronForward(context),
                onTap: () => context.push(AppRoutes.churchLanguages),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.tune),
                title: Text(l10n.customization),
                subtitle: Text(l10n.customizeYourChurch),
                trailing: AppIcons.chevronForward(context),
                onTap: () => context.push(AppRoutes.customization),
              ),
            ),
          ],
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
        ],
      ),
    );
  }

  Future<void> _changeLanguage(
    BuildContext context,
    WidgetRef ref,
    String? code,
  ) async {
    if (code == null) return;
    final l10n = AppLocalizations.of(context);
    await ref.read(localeProvider.notifier).setLocale(Locale(code));
    try {
      await ref
          .read(languageSettingsRepositoryProvider)
          .updatePreferredLanguage(code);
      ref.invalidate(languageProfileProvider);
    } catch (e) {
      if (context.mounted) {
        cw.showErrorSnackbar(context, userFriendlyMessage(e, l10n));
      }
    }
  }
}
