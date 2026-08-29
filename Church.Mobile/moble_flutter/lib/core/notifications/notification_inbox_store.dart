import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/notifications/models/app_notification.dart';

/// Persistent local inbox for FCM notifications (Hive).
///
/// Used by the existing Notifications screen until a backend inbox API exists.
class NotificationInboxStore {
  NotificationInboxStore._();

  static final NotificationInboxStore instance = NotificationInboxStore._();

  static const String _boxName = 'notifications_inbox_v1';
  static const int _maxItems = 100;

  Box<String>? _box;
  Future<void>? _opening;
  bool _hiveReady = false;

  final StreamController<void> _changes =
      StreamController<void>.broadcast();

  Stream<void> get onChanged => _changes.stream;

  Future<void> ensureInitialized() async {
    if (_box != null) return;
    if (_opening != null) return _opening!;
    _opening = _openBox();
    try {
      await _opening;
    } finally {
      _opening = null;
    }
  }

  Future<void> _openBox() async {
    if (!_hiveReady) {
      await Hive.initFlutter();
      _hiveReady = true;
    }
    _box = await Hive.openBox<String>(_boxName);
  }

  Future<Box<String>> _boxAsync() async {
    await ensureInitialized();
    return _box!;
  }

  /// Insert or update. Returns the saved notification (existing wins on duplicate id).
  Future<AppNotification> upsert(
    AppNotification notification, {
    bool markRead = false,
  }) async {
    final box = await _boxAsync();
    final existingJson = box.get(notification.id);
    if (existingJson != null) {
      final existing = AppNotification.fromJson(
        jsonDecode(existingJson) as Map<String, dynamic>,
      );
      final merged = existing.copyWith(
        title: notification.title ?? existing.title,
        body: notification.body ?? existing.body,
        type: notification.type ?? existing.type,
        data: {...existing.data, ...notification.data},
        isRead: markRead || existing.isRead,
      );
      await box.put(notification.id, jsonEncode(merged.toJson()));
      if (kDebugMode) {
        debugPrint('[FCM] Notification updated in inbox id=${merged.id}');
      }
      _changes.add(null);
      return merged;
    }

    final toSave = markRead ? notification.copyWith(isRead: true) : notification;
    await box.put(toSave.id, jsonEncode(toSave.toJson()));
    await _trimIfNeeded(box);
    if (kDebugMode) {
      debugPrint('[FCM] Notification saved successfully id=${toSave.id}');
    }
    _changes.add(null);
    return toSave;
  }

  Future<AppNotification> saveFromRemoteMessage(
    RemoteMessage message, {
    bool markRead = false,
  }) async {
    if (kDebugMode) {
      debugPrint('[FCM] Saving notification id=${resolveNotificationId(message)}');
    }
    return upsert(
      AppNotification.fromRemoteMessage(message, isRead: markRead),
      markRead: markRead,
    );
  }

  Future<AppNotification> saveFromTapPayload(
    Map<String, dynamic> payload, {
    bool markRead = true,
  }) async {
    return upsert(
      AppNotification.fromTapPayload(payload),
      markRead: markRead,
    );
  }

  Future<void> markAsRead(String id) async {
    final box = await _boxAsync();
    final raw = box.get(id);
    if (raw == null) return;
    final item = AppNotification.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    if (item.isRead) return;
    await box.put(id, jsonEncode(item.copyWith(isRead: true).toJson()));
    _changes.add(null);
  }

  Future<List<AppNotification>> getAll() async {
    final box = await _boxAsync();
    final items = <AppNotification>[];
    for (final raw in box.values) {
      try {
        items.add(
          AppNotification.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          ),
        );
      } catch (_) {
        // Skip corrupt entries.
      }
    }
    items.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return items;
  }

  Future<void> _trimIfNeeded(Box<String> box) async {
    if (box.length <= _maxItems) return;
    final items = await getAll();
    final toRemove = items.skip(_maxItems).map((e) => e.id);
    for (final id in toRemove) {
      await box.delete(id);
    }
  }
}
