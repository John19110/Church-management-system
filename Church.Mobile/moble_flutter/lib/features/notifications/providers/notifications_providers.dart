import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_inbox_store.dart';
import '../models/app_notification.dart';

class NotificationInboxNotifier extends StateNotifier<AsyncValue<List<AppNotification>>> {
  NotificationInboxNotifier() : super(const AsyncValue.loading()) {
    _subscription = NotificationInboxStore.instance.onChanged.listen((_) {
      unawaited(refresh());
    });
    unawaited(refresh());
  }

  StreamSubscription<void>? _subscription;

  Future<void> refresh() async {
    try {
      final items = await NotificationInboxStore.instance.getAll();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String id) async {
    await NotificationInboxStore.instance.markAsRead(id);
    await refresh();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

final notificationInboxProvider = StateNotifierProvider<
    NotificationInboxNotifier, AsyncValue<List<AppNotification>>>((ref) {
  return NotificationInboxNotifier();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final inbox = ref.watch(notificationInboxProvider);
  return inbox.maybeWhen(
    data: (items) => items.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
