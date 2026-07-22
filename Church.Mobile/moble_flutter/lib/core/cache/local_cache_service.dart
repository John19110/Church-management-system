import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Simple persistent cache with TTL using Hive.
///
/// Values are stored as JSON strings inside an envelope:
/// - expiresAtUtcMillis: int
/// - payloadJson: string
///
/// This keeps the cache backend swappable while keeping callers type-safe via
/// encode/decode functions.
class LocalCacheService {
  static const String _boxName = 'local_cache_v1';
  static Box<String>? _box;
  static Future<void>? _opening;
  static bool _hiveReady = false;

  /// Opens Hive + the cache box. Safe to call multiple times; used after the
  /// first frame from [main] and lazily from cache read/write methods.
  static Future<void> ensureInitialized() {
    if (_box != null) return Future.value();
    return _opening ??= () async {
      try {
        if (!_hiveReady) {
          await Hive.initFlutter();
          _hiveReady = true;
        }
        _box = await Hive.openBox<String>(_boxName);
      } catch (_) {
        _opening = null;
        rethrow;
      }
    }();
  }

  Future<Box<String>> _boxAsync() async {
    await ensureInitialized();
    return _box!;
  }

  Future<void> putJson({
    required String key,
    required String payloadJson,
    required Duration ttl,
  }) async {
    final box = await _boxAsync();
    final expiresAt = DateTime.now().toUtc().add(ttl);
    final envelope = jsonEncode({
      'expiresAtUtcMillis': expiresAt.millisecondsSinceEpoch,
      'payloadJson': payloadJson,
    });
    await box.put(key, envelope);
  }

  /// Returns the raw payload JSON if present and not expired.
  Future<String?> getJson(String key) async {
    final box = await _boxAsync();
    final envelopeStr = box.get(key);
    if (envelopeStr == null) return null;
    try {
      final env = jsonDecode(envelopeStr) as Map<String, dynamic>;
      final expiresAtUtcMillis = env['expiresAtUtcMillis'];
      final payloadJson = env['payloadJson'];
      if (expiresAtUtcMillis is! int || payloadJson is! String) return null;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        expiresAtUtcMillis,
        isUtc: true,
      );
      if (DateTime.now().toUtc().isAfter(expiresAt)) {
        await box.delete(key);
        return null;
      }
      return payloadJson;
    } catch (_) {
      // Corrupt entry: delete to avoid infinite failures.
      await box.delete(key);
      return null;
    }
  }

  Future<void> remove(String key) async {
    final box = await _boxAsync();
    await box.delete(key);
  }

  /// Deletes only entries that belong to a specific tenant prefix.
  Future<void> clearTenant(int tenantId) async {
    final box = await _boxAsync();
    final prefix = 'tenant_${tenantId}_';
    final keys = box.keys.whereType<String>().where(
      (k) => k.startsWith(prefix),
    );
    await box.deleteAll(keys.toList());
  }

  /// Removes all cached data, including every tenant and user cache entry.
  Future<void> clearAll() async {
    final box = await _boxAsync();
    await box.clear();
  }
}
