import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/routing/app_router.dart';
import '../../core/storage/token_storage.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/notifications/models/app_notification.dart';
import '../../features/notifications/providers/notifications_providers.dart';

/// Listens for FCM / local notification taps and opens the Notifications screen.
///
/// Covers foreground local taps, background [onMessageOpenedApp], and terminated
/// [getInitialMessage] / local launch details (via pending state + GoRouter redirect).
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
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _subscription =
        NotificationService.instance.onNotificationOpened.listen((notification) {
      _openNotificationsScreen(notification);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _flushPendingIfReady();
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  bool get _canNavigate {
    if (ref.read(authStateProvider)) return true;
    return TokenStorage.cachedToken?.isNotEmpty == true;
  }

  void _flushPendingIfReady() {
    if (!_canNavigate) return;
    final pending = NotificationService.instance.pendingOpenedNotification;
    final wantsNav = NotificationService.instance.wantsNotificationsScreen;
    if (pending == null && !wantsNav) return;
    _openNotificationsScreen(pending);
  }

  void _openNotificationsScreen(AppNotification? notification) {
    if (!mounted || _navigating) return;
    if (!_canNavigate) {
      // Keep pending; retry after login / session restore.
      if (notification != null) {
        NotificationService.instance.pendingOpenedNotification = notification;
        NotificationService.instance.requestNotificationsNavigation();
      }
      if (kDebugMode) {
        debugPrint(
          '[FCM] Deferring Notifications navigation until authenticated',
        );
      }
      return;
    }

    _navigating = true;
    try {
      NotificationService.instance.takeNotificationsNavigationRequest();

      if (notification != null) {
        ref
            .read(notificationInboxProvider.notifier)
            .markAsRead(notification.id);
      }
      NotificationService.instance.pendingOpenedNotification = null;

      if (kDebugMode) {
        debugPrint('[FCM] Navigating to Notifications screen');
      }
      // Use GoRouter directly — MaterialApp.builder context is unreliable for go().
      final router = ref.read(routerProvider);
      final alreadyThere =
          router.routerDelegate.currentConfiguration.uri.path ==
              AppRoutes.notifications;
      if (!alreadyThere) {
        router.go(AppRoutes.notifications);
      }
    } finally {
      _navigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(authStateProvider, (previous, next) {
      if (next && previous != true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _flushPendingIfReady();
        });
      }
    });

    return widget.child;
  }
}
