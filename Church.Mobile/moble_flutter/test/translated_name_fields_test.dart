import 'package:church_app/core/l10n/organization_languages.dart';
import 'package:church_app/features/settings/models/language_settings.dart';
import 'package:church_app/features/settings/widgets/translated_name_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChurchLanguages.forNameFields', () {
    test('unconfigured church follows Arabic app language only', () {
      final resolved = ChurchLanguages.forNameFields(
        church: ChurchLanguages.bilingual(isConfigured: false),
        appLanguageCode: OrganizationLanguages.arabic,
      );

      expect(resolved.supportsArabic, isTrue);
      expect(resolved.supportsEnglish, isFalse);
      expect(resolved.isBilingual, isFalse);
    });

    test('unconfigured church follows English app language only', () {
      final resolved = ChurchLanguages.forNameFields(
        church: null,
        appLanguageCode: OrganizationLanguages.english,
      );

      expect(resolved.supportsEnglish, isTrue);
      expect(resolved.supportsArabic, isFalse);
    });

    test('configured bilingual church keeps both languages', () {
      final resolved = ChurchLanguages.forNameFields(
        church: ChurchLanguages.bilingual(isConfigured: true),
        appLanguageCode: OrganizationLanguages.arabic,
      );

      expect(resolved.isBilingual, isTrue);
    });

    test('configured Arabic-only church stays Arabic-only', () {
      const church = ChurchLanguages(
        supportedLanguages: [OrganizationLanguages.arabic],
        defaultLanguage: OrganizationLanguages.arabic,
        isConfigured: true,
      );
      final resolved = ChurchLanguages.forNameFields(
        church: church,
        appLanguageCode: OrganizationLanguages.english,
      );

      expect(resolved.isArabicOnly, isTrue);
      expect(resolved.supportsEnglish, isFalse);
    });
  });

  group('TranslatedNameFields.seedFromStored', () {
    test('Arabic-only prefers Arabic display name in primary controller', () {
      final english = TextEditingController();
      final arabic = TextEditingController();
      addTearDown(english.dispose);
      addTearDown(arabic.dispose);

      const church = ChurchLanguages(
        supportedLanguages: [OrganizationLanguages.arabic],
        defaultLanguage: OrganizationLanguages.arabic,
        isConfigured: true,
      );

      TranslatedNameFields.seedFromStored(
        church: church,
        english: english,
        arabic: arabic,
        displayName: 'Buses',
        displayNameAr: 'أتوبيسات',
      );

      expect(english.text, 'أتوبيسات');
      expect(arabic.text, 'أتوبيسات');
    });

    test('English-only keeps English primary and Arabic companion', () {
      final english = TextEditingController();
      final arabic = TextEditingController();
      addTearDown(english.dispose);
      addTearDown(arabic.dispose);

      const church = ChurchLanguages(
        supportedLanguages: [OrganizationLanguages.english],
        defaultLanguage: OrganizationLanguages.english,
        isConfigured: true,
      );

      TranslatedNameFields.seedFromStored(
        church: church,
        english: english,
        arabic: arabic,
        displayName: 'Buses',
        displayNameAr: 'أتوبيسات',
      );

      expect(english.text, 'Buses');
      expect(arabic.text, 'أتوبيسات');
    });
  });

  group('TranslatedNameFields.mirrorArabicOnlyName', () {
    test('copies primary into Arabic for Arabic-only churches', () {
      final english = TextEditingController(text: 'إدارة');
      final arabic = TextEditingController();
      addTearDown(english.dispose);
      addTearDown(arabic.dispose);

      const church = ChurchLanguages(
        supportedLanguages: [OrganizationLanguages.arabic],
        defaultLanguage: OrganizationLanguages.arabic,
        isConfigured: true,
      );

      TranslatedNameFields.mirrorArabicOnlyName(
        church: church,
        english: english,
        arabic: arabic,
      );

      expect(arabic.text, 'إدارة');
    });
  });
}
