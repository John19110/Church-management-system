import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/organization_languages.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../settings/providers/language_settings_providers.dart';

/// Controls the My Church application UI language. Uses [localeProvider].
/// Independent of church customization languages.
class ApplicationLanguageCard extends ConsumerWidget {
  const ApplicationLanguageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.applicationLanguage),
            subtitle: Text(l10n.applicationLanguageDescription),
          ),
          const Divider(height: 0),
          RadioListTile<String>(
            value: OrganizationLanguages.english,
            groupValue: locale.languageCode,
            title: Text(l10n.english),
            onChanged: (value) {
              if (value != null) _changeLanguage(context, ref, value);
            },
          ),
          RadioListTile<String>(
            value: OrganizationLanguages.arabic,
            groupValue: locale.languageCode,
            title: Text(l10n.arabic),
            onChanged: (value) {
              if (value != null) _changeLanguage(context, ref, value);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _changeLanguage(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) async {
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
