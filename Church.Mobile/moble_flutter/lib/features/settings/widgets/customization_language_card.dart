import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/customization_language_provider.dart';
import '../models/language_settings.dart';
import '../providers/language_settings_providers.dart';
import 'language_option_radios.dart';

/// Working language for custom fields and features. Does not change app UI locale.
class CustomizationLanguageCard extends ConsumerWidget {
  const CustomizationLanguageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(resolvedCustomizationLanguageProvider);
    final church = ref.watch(churchLanguagesProvider).valueOrNull ??
        ChurchLanguages.bilingual();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(l10n.customizationLanguage),
            subtitle: Text(l10n.customizationLanguageDescription),
          ),
          const Divider(height: 0),
          LanguageOptionRadios(
            groupValue: selected,
            supportedLanguages: church.supportedLanguages,
            onChanged: (code) =>
                ref.read(customizationLanguageProvider.notifier).setLanguage(code),
          ),
        ],
      ),
    );
  }
}
