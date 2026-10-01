import '../../../core/l10n/organization_languages.dart';

class ChurchLanguages {
  final List<String> supportedLanguages;
  final String defaultLanguage;
  final bool isConfigured;

  const ChurchLanguages({
    required this.supportedLanguages,
    required this.defaultLanguage,
    this.isConfigured = false,
  });

  factory ChurchLanguages.bilingual({bool isConfigured = false}) =>
      ChurchLanguages(
        supportedLanguages: List<String>.from(OrganizationLanguages.bilingual),
        defaultLanguage: OrganizationLanguages.english,
        isConfigured: isConfigured,
      );

  factory ChurchLanguages.fromJson(Map<String, dynamic> json) {
    final raw = json['supportedLanguages'];
    final supported = raw is List
        ? OrganizationLanguages.parseSupported(raw.map((e) => e.toString()))
        : OrganizationLanguages.parseSupportedRaw(raw?.toString());
    return ChurchLanguages(
      supportedLanguages: supported,
      defaultLanguage: OrganizationLanguages.normalizeDefault(
        json['defaultLanguage']?.toString(),
        supported,
      ),
      isConfigured: json['isCustomizationLanguagesConfigured'] == true ||
          json['isConfigured'] == true,
    );
  }

  bool get supportsEnglish =>
      OrganizationLanguages.supportsEnglish(supportedLanguages);
  bool get supportsArabic =>
      OrganizationLanguages.supportsArabic(supportedLanguages);
  bool get isBilingual => OrganizationLanguages.isBilingual(supportedLanguages);

  Map<String, dynamic> toJson() => {
        'supportedLanguages': supportedLanguages,
        'defaultLanguage': defaultLanguage,
        'isCustomizationLanguagesConfigured': isConfigured,
      };
}

class LanguageProfile {
  final String? preferredLanguage;
  final ChurchLanguages church;

  const LanguageProfile({
    required this.preferredLanguage,
    required this.church,
  });

  factory LanguageProfile.fromJson(Map<String, dynamic> json) {
    final church = ChurchLanguages.fromJson(json);
    final preferred = OrganizationLanguages.normalize(
      json['preferredLanguage']?.toString(),
    );
    return LanguageProfile(
      preferredLanguage: preferred.isEmpty ? null : preferred,
      church: church,
    );
  }
}
