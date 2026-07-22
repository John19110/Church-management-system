import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../startup/splash_theme_sync.dart';
import 'shared_preferences_provider.dart';

const themePrefsKey = 'app_theme_mode'; // light | dark | system

ThemeMode themeModeFromPrefs(String? raw) {
  switch (raw) {
    case 'dark':
      return ThemeMode.dark;
    case 'system':
      return ThemeMode.system;
    case 'light':
    default:
      return ThemeMode.light;
  }
}

String themeModeToPrefs(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
    ThemeMode.light => 'light',
  };
}

class ThemeController extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeController({required SharedPreferences prefs, required ThemeMode initial})
      : _prefs = prefs,
        super(initial);

  static ThemeMode loadInitial(SharedPreferences prefs) {
    return themeModeFromPrefs(prefs.getString(themePrefsKey));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(themePrefsKey, themeModeToPrefs(mode));
    await SplashThemeSync.sync(mode);
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeController(
    prefs: prefs,
    initial: ThemeController.loadInitial(prefs),
  );
});
