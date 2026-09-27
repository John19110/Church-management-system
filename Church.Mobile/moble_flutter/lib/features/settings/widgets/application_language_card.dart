import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../models/language_settings.dart';
import '../providers/language_settings_providers.dart';
import 'language_option_radios.dart';

/// Controls the My Church application UI language. Uses [localeProvider].
class ApplicationLanguageCard extends ConsumerWidget {
  const ApplicationLanguageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final church = ref.watch(churchLanguagesProvider).valueOrNull ??
        ChurchLanguages.bilingual();
    final supported = List<String>.from(church.supportedLanguages);
    if (!supported.contains(locale.languageCode)) {
      supported.add(locale.languageCode);
    }

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
          LanguageOptionRadios(
            groupValue: locale.languageCode,
            supportedLanguages: supported,
            onChanged: (code) => _changeLanguage(context, ref, code),
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
