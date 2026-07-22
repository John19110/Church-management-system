import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// JWT persistence with an in-memory cache to avoid repeated secure-storage
/// reads during startup (router redirect, Dio interceptor, providers).
class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static String? _cachedToken;
  static bool _cacheLoaded = false;

  /// Preload token once during app bootstrap (call from [main]).
  static Future<void> warmCache() async {
    _cachedToken = await _storage.read(key: AppConstants.tokenKey);
    _cacheLoaded = true;
  }

  /// True after [warmCache] or any read/write has populated the cache.
  static bool get isCacheWarm => _cacheLoaded;

  /// Synchronous read when the cache has already been populated.
  static String? get cachedToken => _cacheLoaded ? _cachedToken : null;

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    _cacheLoaded = true;
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    if (_cacheLoaded) return _cachedToken;
    _cachedToken = await _storage.read(key: AppConstants.tokenKey);
    _cacheLoaded = true;
    return _cachedToken;
  }

  static Future<void> deleteToken() async {
    _cachedToken = null;
    _cacheLoaded = true;
    await _storage.delete(key: AppConstants.tokenKey);
  }

  /// Removes every secure-storage value owned by this application.
  static Future<void> clearAll() async {
    _cachedToken = null;
    _cacheLoaded = true;
    await _storage.deleteAll();
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
