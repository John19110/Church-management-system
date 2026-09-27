import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/models/language_settings.dart';
import '../../features/settings/providers/language_settings_providers.dart';
import '../l10n/organization_languages.dart';
import 'shared_preferences_provider.dart';

const customizationLocalePrefsKey = 'customization_locale';

String resolveCustomizationLanguage({
  required String stored,
  required ChurchLanguages church,
}) {
  return OrganizationLanguages.normalizePreferred(
        stored,
        church.supportedLanguages,
      ) ??
      church.defaultLanguage;
}

class CustomizationLanguageController extends StateNotifier<String> {
  final SharedPreferences _prefs;

  CustomizationLanguageController({
    required SharedPreferences prefs,
    required String initial,
  })  : _prefs = prefs,
        super(initial);

  static String loadInitial(SharedPreferences prefs) {
    return OrganizationLanguages.normalize(
      prefs.getString(customizationLocalePrefsKey),
    );
  }

  Future<void> setLanguage(String code) async {
    final normalized = OrganizationLanguages.normalize(code);
    if (normalized.isEmpty) return;
    state = normalized;
    await _prefs.setString(customizationLocalePrefsKey, normalized);
  }
}

/// Stored working language for custom fields/features. Independent of app locale.
final customizationLanguageProvider =
    StateNotifierProvider<CustomizationLanguageController, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CustomizationLanguageController(
    prefs: prefs,
    initial: CustomizationLanguageController.loadInitial(prefs),
  );
});

/// Resolved against the church's supported languages. Does not change app UI locale.
final resolvedCustomizationLanguageProvider = Provider<String>((ref) {
  final stored = ref.watch(customizationLanguageProvider);
  final church = ref.watch(churchLanguagesProvider).valueOrNull ??
      ChurchLanguages.bilingual();
  return resolveCustomizationLanguage(stored: stored, church: church);
});
