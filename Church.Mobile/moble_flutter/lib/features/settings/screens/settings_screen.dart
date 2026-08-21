import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';

/// App-wide settings: theme/language for all roles; Custom Fields for admins.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final canManageFields = AuthRoleUtils.canManageCustomFields(role);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final isArabic = locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.language),
                  subtitle: Text(isArabic ? l10n.arabic : l10n.english),
                  trailing: TextButton(
                    onPressed: () =>
                        ref.read(localeProvider.notifier).toggle(),
                    child: Text(isArabic ? l10n.english : l10n.arabic),
                  ),
                  onTap: () => ref.read(localeProvider.notifier).toggle(),
                ),
              ],
            ),
          ),
          if (canManageFields) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.tune),
                title: Text(l10n.customFields),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.customFieldsHub),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
