import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'shared_preferences_provider.dart';

const _localePrefsKey = 'app_locale'; // en | ar

Locale _localeFromPrefs(String? raw) {
  switch (raw) {
    case 'ar':
      return const Locale('ar');
    case 'en':
    default:
      return const Locale('en');
  }
}

String _localeToPrefs(Locale locale) {
  return locale.languageCode == 'ar' ? 'ar' : 'en';
}

class LocaleController extends StateNotifier<Locale> {
  final SharedPreferences _prefs;

  LocaleController({required SharedPreferences prefs, required Locale initial})
      : _prefs = prefs,
        super(initial);

  static Locale loadInitial(SharedPreferences prefs) {
    return _localeFromPrefs(prefs.getString(_localePrefsKey));
  }

  Future<void> setLocale(Locale locale) async {
    final normalized =
        locale.languageCode == 'ar' ? const Locale('ar') : const Locale('en');
    state = normalized;
    await _prefs.setString(_localePrefsKey, _localeToPrefs(normalized));
  }

  Future<void> toggle() async {
    final next = state.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    await setLocale(next);
  }
}

final localeProvider = StateNotifierProvider<LocaleController, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleController(
    prefs: prefs,
    initial: LocaleController.loadInitial(prefs),
  );
});
