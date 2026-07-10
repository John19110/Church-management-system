import 'dart:convert';

import 'package:hive/hive.dart';

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

  static Future<void> ensureInitialized() async {
    _box ??= await Hive.openBox<String>(_boxName);
  }

  Box<String> get _b {
    final box = _box;
    if (box == null) {
      throw StateError(
        'LocalCacheService not initialized. Call LocalCacheService.ensureInitialized() at startup.',
      );
    }
    return box;
  }

  Future<void> putJson({
    required String key,
    required String payloadJson,
    required Duration ttl,
  }) async {
    final expiresAt = DateTime.now().toUtc().add(ttl);
    final envelope = jsonEncode({
      'expiresAtUtcMillis': expiresAt.millisecondsSinceEpoch,
      'payloadJson': payloadJson,
    });
    await _b.put(key, envelope);
  }

  /// Returns the raw payload JSON if present and not expired.
  Future<String?> getJson(String key) async {
    final envelopeStr = _b.get(key);
    if (envelopeStr == null) return null;
    try {
      final env = jsonDecode(envelopeStr) as Map<String, dynamic>;
      final expiresAtUtcMillis = env['expiresAtUtcMillis'];
      final payloadJson = env['payloadJson'];
      if (expiresAtUtcMillis is! int || payloadJson is! String) return null;
      final expiresAt =
          DateTime.fromMillisecondsSinceEpoch(expiresAtUtcMillis, isUtc: true);
      if (DateTime.now().toUtc().isAfter(expiresAt)) {
        await _b.delete(key);
        return null;
      }
      return payloadJson;
    } catch (_) {
      // Corrupt entry: delete to avoid infinite failures.
      await _b.delete(key);
      return null;
    }
  }

  Future<void> remove(String key) => _b.delete(key);

  /// Deletes only entries that belong to a specific tenant prefix.
  Future<void> clearTenant(int tenantId) async {
    final prefix = 'tenant_${tenantId}_';
    final keys = _b.keys.whereType<String>().where((k) => k.startsWith(prefix));
    await _b.deleteAll(keys.toList());
  }
}

