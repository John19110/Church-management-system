import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'local_cache_service.dart';

typedef JsonMap = Map<String, dynamic>;

/// Cache-first orchestrator:
/// - emit cached data immediately (if present)
/// - refresh in background
/// - coalesce duplicate fetches per key (prevents duplicate API calls)
/// - if offline / request fails, keep serving cached data
class CacheManager {
  final LocalCacheService _cache;
  final Map<String, Future<String>> _inFlightJsonByKey = {};

  CacheManager(this._cache);

  String tenantKey(int tenantId, String segment) => 'tenant_${tenantId}_$segment';

  String tenantRoleKey(int tenantId, String role, String segment) =>
      'tenant_${tenantId}_${role}_$segment';

  String tenantUserKey(int tenantId, String userId, String segment) =>
      'tenant_${tenantId}_user_${userId}_$segment';

  Future<T?> tryRead<T>(
    String key, {
    required T Function(JsonMap json) fromJson,
  }) async {
    final jsonStr = await _cache.getJson(key);
    if (jsonStr == null) return null;
    final decoded = jsonDecode(jsonStr);
    if (decoded is! JsonMap) return null;
    return fromJson(decoded);
  }

  Future<void> write<T>(
    String key,
    T value, {
    required JsonMap Function(T value) toJson,
    required Duration ttl,
  }) async {
    final payloadJson = jsonEncode(toJson(value));
    await _cache.putJson(key: key, payloadJson: payloadJson, ttl: ttl);
  }

  /// Stream that first emits cached value (if any), then emits refreshed value.
  Stream<T> cacheFirstStream<T>({
    required String key,
    required Duration ttl,
    required Future<T> Function() fetch,
    required JsonMap Function(T value) toJson,
    required T Function(JsonMap json) fromJson,
  }) async* {
    final cached = await tryRead<T>(key, fromJson: fromJson);
    if (cached != null) {
      yield cached;
    }

    try {
      final fresh = await _fetchJsonCoalesced(
        key,
        fetch: () async {
          final v = await fetch();
          return jsonEncode(toJson(v));
        },
      );

      // Only write once we have fresh data.
      await _cache.putJson(key: key, payloadJson: fresh, ttl: ttl);
      final decoded = jsonDecode(fresh);
      if (decoded is JsonMap) {
        final parsed = fromJson(decoded);
        // If there was no cache, this will be the first emission.
        if (cached == null) {
          yield parsed;
        } else {
          // Emit again to update UI; callers can de-dupe if desired.
          yield parsed;
        }
      }
    } on DioException {
      // Offline / timeout / server issues: keep cached if it existed; otherwise rethrow.
      if (cached == null) rethrow;
    }
  }

  Future<String> _fetchJsonCoalesced(
    String key, {
    required Future<String> Function() fetch,
  }) {
    final existing = _inFlightJsonByKey[key];
    if (existing != null) return existing;
    final future = fetch().whenComplete(() {
      _inFlightJsonByKey.remove(key);
    });
    _inFlightJsonByKey[key] = future;
    return future;
  }
}

