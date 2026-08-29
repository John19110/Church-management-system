import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/routing/app_router.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/notifications/models/app_notification.dart';
import '../../features/notifications/providers/notifications_providers.dart';

/// Listens for FCM notification taps and navigates once auth + router are ready.
class NotificationNavigationListener extends ConsumerStatefulWidget {
  const NotificationNavigationListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationNavigationListener> createState() =>
      _NotificationNavigationListenerState();
}

class _NotificationNavigationListenerState
    extends ConsumerState<NotificationNavigationListener> {
  StreamSubscription<AppNotification>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription =
        NotificationService.instance.onNotificationOpened.listen((notification) {
      _handleOpen(notification);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!ref.read(authStateProvider)) return;
      final pending = NotificationService.instance.pendingOpenedNotification;
      if (pending != null) {
        _handleOpen(pending);
      }
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  void _handleOpen(AppNotification notification) {
    if (!ref.read(authStateProvider)) return;
    if (!mounted) return;

    ref.read(notificationInboxProvider.notifier).markAsRead(notification.id);

    if (kDebugMode) {
      debugPrint('[FCM] Navigating to Notifications screen');
    }
    context.go(AppRoutes.notifications);
    NotificationService.instance.pendingOpenedNotification = null;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(authStateProvider, (previous, next) {
      if (next && previous != true) {
        final pending = NotificationService.instance.pendingOpenedNotification;
        if (pending != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _handleOpen(pending);
          });
        }
      }
    });

    return widget.child;
  }
}
