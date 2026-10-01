import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/organization_languages.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../models/language_settings.dart';
import '../providers/language_settings_providers.dart';

/// Name inputs for custom fields/features based on church customization languages.
///
/// [english] maps to the required API `displayName` column. For Arabic-only churches
/// the single name is still stored there (and mirrored to Arabic on save by callers
/// that use [mirrorArabicOnlyName]).
class TranslatedNameFields extends ConsumerWidget {
  final TextEditingController english;
  final TextEditingController arabic;
  final String? englishLabel;
  final String? arabicLabel;
  final String? singleLanguageLabel;

  const TranslatedNameFields({
    super.key,
    required this.english,
    required this.arabic,
    this.englishLabel,
    this.arabicLabel,
    this.singleLanguageLabel,
  });

  /// When the church is Arabic-only, keep DisplayNameAr in sync with the single name.
  static void mirrorArabicOnlyName({
    required ChurchLanguages church,
    required TextEditingController english,
    required TextEditingController arabic,
  }) {
    if (church.supportsArabic && !church.supportsEnglish) {
      arabic.text = english.text;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final church = ref.watch(churchLanguagesProvider).valueOrNull ??
        ChurchLanguages.bilingual(isConfigured: true);
    final showEnglish = church.supportsEnglish;
    final showArabic = church.supportsArabic;
    final bilingual = showEnglish && showArabic;
    final appIsArabic = l10n.locale.languageCode == OrganizationLanguages.arabic;

    if (!bilingual) {
      // Single language: one required field bound to the API primary displayName.
      return AppTextField(
        controller: english,
        label: '${singleLanguageLabel ?? l10n.displayNameLabel} *',
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.sentences,
        validator: (v) =>
            v == null || v.trim().isEmpty ? l10n.displayNameRequired : null,
      );
    }

    final englishField = AppTextField(
      controller: english,
      label: '${englishLabel ?? l10n.displayNameEnglishLabel} *',
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.sentences,
      validator: (v) =>
          v == null || v.trim().isEmpty ? l10n.displayNameRequired : null,
    );

    final arabicField = AppTextField(
      controller: arabic,
      label: '${arabicLabel ?? l10n.displayNameArabicLabel} *',
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.sentences,
      validator: (v) =>
          v == null || v.trim().isEmpty ? l10n.displayNameRequired : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (appIsArabic) ...[
          arabicField,
          const SizedBox(height: AppSpacing.sm),
          englishField,
        ] else ...[
          englishField,
          const SizedBox(height: AppSpacing.sm),
          arabicField,
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.customizationNamePerLanguageHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
