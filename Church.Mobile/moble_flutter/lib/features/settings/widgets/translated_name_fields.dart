import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/organization_languages.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../models/language_settings.dart';
import '../providers/language_settings_providers.dart';

class TranslatedNameFields extends ConsumerWidget {
  final TextEditingController english;
  final TextEditingController arabic;
  final String? englishLabel;
  final String? arabicLabel;

  const TranslatedNameFields({
    super.key,
    required this.english,
    required this.arabic,
    this.englishLabel,
    this.arabicLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final church = ref.watch(churchLanguagesProvider).valueOrNull ??
        ChurchLanguages.bilingual();
    final defaultLanguage = church.defaultLanguage;
    final showEnglish = church.supportsEnglish;
    final showArabic = church.supportsArabic;
    final englishRequired = defaultLanguage == OrganizationLanguages.english ||
        !showArabic;
    final arabicRequired = defaultLanguage == OrganizationLanguages.arabic ||
        !showEnglish;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showEnglish) ...[
          AppTextField(
            controller: english,
            label: englishRequired
                ? '${englishLabel ?? l10n.displayNameEnglishLabel} *'
                : (englishLabel ?? l10n.displayNameEnglishLabel),
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) {
              if (!englishRequired) return null;
              return v == null || v.trim().isEmpty
                  ? l10n.displayNameRequired
                  : null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (showArabic) ...[
          AppTextField(
            controller: arabic,
            label: arabicRequired
                ? '${arabicLabel ?? l10n.displayNameArabicLabel} *'
                : (arabicLabel ?? l10n.displayNameArabicLabel),
            validator: (v) {
              if (!arabicRequired) return null;
              return v == null || v.trim().isEmpty
                  ? l10n.displayNameRequired
                  : null;
            },
          ),
          if (!arabicRequired)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: AppSpacing.sm),
              child: Text(
                l10n.arabicTranslationOptional,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
