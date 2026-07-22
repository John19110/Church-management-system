import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/cache/local_cache_service.dart';
import '../../../core/startup/splash_theme_sync.dart';
import '../../../core/storage/token_storage.dart';

/// Clears all local account data after permanent server-side deletion.
class AccountDataCleaner {
  AccountDataCleaner._();

  static Future<void> clear(SharedPreferences preferences) async {
    // Each store is best-effort so one plugin failure cannot leave the deleted
    // user inside the authenticated application.
    try {
      await TokenStorage.clearAll();
    } catch (_) {
      // The in-memory token is already cleared before secure-storage I/O.
    }
    try {
      await LocalCacheService().clearAll();
    } catch (_) {
      // A later app start can safely recreate/overwrite this cache.
    }
    try {
      await preferences.clear();
    } catch (_) {
      // Continue to reset the native theme and in-memory image cache.
    }

    // A deleted account's theme must not leak into the next user's session.
    await SplashThemeSync.sync(ThemeMode.light);

    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  }
}
