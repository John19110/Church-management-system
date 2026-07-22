import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';

/// Keeps the Android native splash theme in sync with [ThemeMode].
class SplashThemeSync {
  SplashThemeSync._();

  static const _channel = MethodChannel('com.Church.MyApp/splash_theme');

  static String modeToNative(ThemeMode mode) => switch (mode) {
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
      };

  /// Persists mode for the next cold start and applies AppCompat night mode now.
  static Future<void> sync(ThemeMode mode) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('setThemeMode', modeToNative(mode));
    } catch (_) {
      // Channel unavailable (tests / early isolate) — next launch still uses prefs.
    }
  }
}
