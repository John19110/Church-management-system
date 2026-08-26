import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import '../api/dio_client.dart';
import 'fcm_token_registrar.dart';
import 'notification_payload.dart';

const String _prefsPermissionPromptedKey = 'fcm_notification_permission_prompted';
const String _androidChannelId = 'my_church_default';
const String _androidChannelName = 'My Church';
const String _androidChannelDescription =
    'Church announcements, meetings, and updates';

/// Top-level background isolate handler (required by firebase_messaging).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is available in the background isolate.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint(
      '[FCM] Background message id=${message.messageId} '
      'type=${message.data['type']}',
    );
  }
}

/// Firebase Cloud Messaging + local notification presentation for Android.
///
/// Call [NotificationService.bootstrap] once from `main` before `runApp`.
/// Call [NotificationService.instance.onUserAuthenticated] after login (or
/// when a stored JWT is restored) so the FCM token can sync to the API later.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  FcmTokenRegistrar? _registrar;
  String? _currentToken;
  bool _bootstrapped = false;
  bool _handlersAttached = false;

  /// Latest notification opened by the user (FCM or local). Ready for future
  /// deep-link routing without changing navigation today.
  NotificationPayload? pendingNavigationPayload;

  /// Fires when the user taps a notification (foreground local or FCM open).
  final StreamController<NotificationPayload> _openedController =
      StreamController<NotificationPayload>.broadcast();

  Stream<NotificationPayload> get onNotificationOpened =>
      _openedController.stream;

  String? get currentToken => _currentToken;

  /// Initialize Firebase, local notifications, and FCM listeners.
  /// Safe to call once; subsequent calls are no-ops.
  static Future<void> bootstrap() async {
    await instance._bootstrap();
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      debugPrint('[FCM] Firebase initialized (project=my-church-e838a)');
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initLocalNotifications();
    await _createAndroidChannel();
    _attachMessageHandlers();

    _registrar = FcmTokenRegistrar(createDio());
    _bootstrapped = true;
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@drawable/ic_notification');
    const initSettings = InitializationSettings(android: androidInit);

    await _local.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDescription,
      importance: Importance.high,
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _attachMessageHandlers() {
    if (_handlersAttached) return;
    _handlersAttached = true;

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    _messaging.onTokenRefresh.listen((token) async {
      _currentToken = token;
      if (kDebugMode) {
        debugPrint('[FCM] Token refreshed: ${_preview(token)}');
      }
      await _registrar?.syncToken(token);
    });
  }

  /// Request permission (once per install preference), fetch token, sync API.
  Future<void> onUserAuthenticated() async {
    if (!_bootstrapped) await _bootstrap();

    await _requestPermissionIfNeeded();
    await _refreshAndSyncToken();

    // Cold start: app opened from a terminated-state notification.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleOpenedMessage(initial);
    }

    final launch = await _local.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      final response = launch!.notificationResponse;
      if (response?.payload != null) {
        final payload =
            NotificationPayload.tryParsePayloadString(response!.payload);
        if (payload != null) {
          pendingNavigationPayload = payload;
          _openedController.add(payload);
        }
      }
    }
  }

  Future<void> onUserLoggedOut() async {
    final token = _currentToken;
    await _registrar?.clearToken(token);
    // Keep local FCM registration; token may be reused after next login.
  }

  Future<void> _requestPermissionIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyPrompted = prefs.getBool(_prefsPermissionPromptedKey) ?? false;

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final enabled = await androidPlugin?.areNotificationsEnabled();
    if (enabled == true) {
      return;
    }

    // Avoid re-prompting every launch after the user already answered.
    if (alreadyPrompted) {
      if (kDebugMode) {
        debugPrint('[FCM] Notifications disabled; not re-prompting');
      }
      return;
    }

    final granted = await androidPlugin?.requestNotificationsPermission();
    await prefs.setBool(_prefsPermissionPromptedKey, true);

    // Also align with Firebase messaging permission API (no-op on older Android).
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      debugPrint('[FCM] POST_NOTIFICATIONS granted=$granted');
    }
  }

  Future<void> _refreshAndSyncToken() async {
    try {
      final token = await _messaging.getToken();
      _currentToken = token;
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          debugPrint('[FCM] getToken() returned null');
        }
        return;
      }
      if (kDebugMode) {
        debugPrint('[FCM] Registration token: $token');
      }
      await _registrar?.syncToken(token);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] getToken failed: $e');
      }
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint(
        '[FCM] Foreground message id=${message.messageId} '
        'title=${message.notification?.title} data=${message.data}',
      );
    }

    final notification = message.notification;
    final title = notification?.title ?? message.data['title'];
    final body = notification?.body ?? message.data['body'];
    if (title == null && body == null) {
      // Data-only: no UI chrome; still available via listeners later.
      return;
    }

    final payload = NotificationPayload.fromData(message.data);
    await _local.show(
      id: message.hashCode,
      title: title?.toString(),
      body: body?.toString(),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
      ),
      payload: payload.toPayloadString(),
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    _handleOpenedMessage(message);
  }

  void _handleOpenedMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint(
        '[FCM] Opened from notification type=${message.data['type']} '
        'data=${message.data}',
      );
    }
    final payload = NotificationPayload.fromData(message.data);
    pendingNavigationPayload = payload;
    _openedController.add(payload);
    // Deep-link navigation will consume [pendingNavigationPayload] / stream
    // once routes for meeting/announcement are wired.
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final payload =
        NotificationPayload.tryParsePayloadString(response.payload);
    if (payload == null) return;
    pendingNavigationPayload = payload;
    _openedController.add(payload);
    if (kDebugMode) {
      debugPrint(
        '[FCM] Local notification tap type=${payload.type} '
        'data=${payload.data}',
      );
    }
  }

  static String _preview(String token) {
    if (token.length <= 12) return '***';
    return '${token.substring(0, 8)}…${token.substring(token.length - 4)}';
  }
}

/// Optional helper for encoding arbitrary maps when constructing test payloads.
String encodeNotificationData(Map<String, String> data) => jsonEncode(data);
