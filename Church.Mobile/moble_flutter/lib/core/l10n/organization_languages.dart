/// Church supported languages vs user preferred language. Codes: `en`, `ar`.
class OrganizationLanguages {
  static const english = 'en';
  static const arabic = 'ar';

  static const bilingual = [english, arabic];

  static String normalize(String? code) {
    final value = (code ?? '').trim().toLowerCase();
    if (value == 'ar' || value == 'arabic' || value == 'العربية') {
      return arabic;
    }
    if (value == 'en' || value == 'english') {
      return english;
    }
    return '';
  }

  static List<String> parseSupported(Iterable<String>? raw) {
    final codes = <String>[];
    for (final item in raw ?? const <String>[]) {
      final code = normalize(item);
      if ((code == english || code == arabic) && !codes.contains(code)) {
        codes.add(code);
      }
    }
    return codes.isEmpty ? List<String>.from(bilingual) : codes;
  }

  static List<String> parseSupportedRaw(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return List<String>.from(bilingual);
    }
    return parseSupported(raw.split(','));
  }

  static String normalizeDefault(String? defaultCode, List<String> supported) {
    final code = normalize(defaultCode);
    if (supported.contains(code)) return code;
    return supported.isNotEmpty ? supported.first : english;
  }

  static String? normalizePreferred(String? preferred, List<String> supported) {
    final code = normalize(preferred);
    if (code.isEmpty || !supported.contains(code)) return null;
    return code;
  }

  static bool supportsEnglish(List<String> supported) =>
      supported.contains(english);

  static bool supportsArabic(List<String> supported) =>
      supported.contains(arabic);

  static bool isBilingual(List<String> supported) =>
      supportsEnglish(supported) && supportsArabic(supported);

  static String pickTranslation({
    required String userLanguage,
    required String defaultLanguage,
    required String? english,
    required String? arabic,
  }) {
    final en = english?.trim() ?? '';
    final ar = arabic?.trim() ?? '';
    final preferred = userLanguage == arabic ? ar : en;
    if (preferred.isNotEmpty) return preferred;
    final fallback = defaultLanguage == arabic ? ar : en;
    if (fallback.isNotEmpty) return fallback;
    return en.isNotEmpty ? en : ar;
  }
}
