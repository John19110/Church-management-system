import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import '../../features/notifications/models/app_notification.dart';
import '../api/dio_client.dart';
import 'fcm_token_registrar.dart';
import 'notification_image_helper.dart';
import 'notification_inbox_store.dart';
import 'notification_payload.dart';

const String _prefsPermissionPromptedKey = 'fcm_notification_permission_prompted';
const String _androidChannelId = 'my_church_default';

/// [firebase_messaging] supports Android, iOS, macOS, and Web — not Windows/Linux.
bool _isFcmSupported() {
  if (kIsWeb) return true;
  return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
}
const String _androidChannelName = 'My Church';
const String _androidChannelDescription =
    'Church announcements, meetings, and updates';

/// Top-level background isolate handler (required by firebase_messaging).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint('[FCM] Background message received');
    debugPrint('[FCM] Message ID: ${message.messageId}');
    debugPrint('[FCM] Data: ${message.data}');
  }
  await NotificationInboxStore.instance.saveFromRemoteMessage(message);
}

/// Firebase Cloud Messaging + local notification presentation for Android.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  FirebaseMessaging? _messagingField;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  FcmTokenRegistrar? _registrar;
  String? _currentToken;
  bool _bootstrapped = false;
  bool _handlersAttached = false;
  Future<void>? _bootstrapInFlight;
  bool _coldStartNotificationChecked = false;

  /// Id of the last opened notification processed this session (dedup taps).
  String? _lastOpenedNotificationId;

  /// Latest opened notification for navigation after auth/router is ready.
  AppNotification? pendingOpenedNotification;

  final StreamController<AppNotification> _openedController =
      StreamController<AppNotification>.broadcast();

  Stream<AppNotification> get onNotificationOpened => _openedController.stream;

  /// @deprecated Use [pendingOpenedNotification] — kept for compatibility.
  NotificationPayload? get pendingNavigationPayload {
    final n = pendingOpenedNotification;
    if (n == null) return null;
    return NotificationPayload(type: n.type, data: n.data);
  }

  FirebaseMessaging get _messaging {
    final messaging = _messagingField;
    if (messaging == null) {
      throw StateError(
        'NotificationService used before Firebase bootstrap completed.',
      );
    }
    return messaging;
  }

  String? get currentToken => _currentToken;

  static Future<void> bootstrap() async {
    await instance._bootstrap();
  }

  /// Requests OS notification permission once on first launch (after [bootstrap]).
  static Future<void> requestLaunchNotificationPermission() async {
    await instance._requestPermissionIfNeeded();
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    if (_bootstrapInFlight != null) return _bootstrapInFlight!;

    final inFlight = _doBootstrap();
    _bootstrapInFlight = inFlight;
    try {
      await inFlight;
    } finally {
      if (identical(_bootstrapInFlight, inFlight)) {
        _bootstrapInFlight = null;
      }
    }
  }

  Future<void> _doBootstrap() async {
    if (_bootstrapped) return;

    if (!_isFcmSupported()) {
      if (kDebugMode) {
        debugPrint(
          '[FCM] Push notifications are not supported on this platform; '
          'skipping Firebase/FCM bootstrap',
        );
      }
      await NotificationInboxStore.instance.ensureInitialized();
      _bootstrapped = true;
      return;
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    _messagingField ??= FirebaseMessaging.instance;

    if (kDebugMode) {
      debugPrint('[FCM] Firebase initialized (project=my-church-e838a)');
    }

    await NotificationInboxStore.instance.ensureInitialized();

    // Background isolate handler and local notifications are mobile-only.
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _initLocalNotifications();
      await _createAndroidChannel();
    }

    await _configureForegroundPresentation();
    _attachMessageHandlers();

    _registrar = FcmTokenRegistrar(createDio());
    await _processColdStartNotificationIfNeeded();
    _bootstrapped = true;
  }

  /// Handles notification that launched the app from terminated state (no auth required).
  Future<void> _processColdStartNotificationIfNeeded() async {
    if (_coldStartNotificationChecked) return;
    _coldStartNotificationChecked = true;

    if (kDebugMode) {
      debugPrint('[FCM] Checking initial message');
    }
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      if (kDebugMode) {
        debugPrint('[FCM] Initial notification found');
      }
      await _handleOpenedMessage(initial, source: 'terminated');
      return;
    }

    if (!kIsWeb) {
      final launch = await _local.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        final payload = _decodeTapPayload(launch!.notificationResponse?.payload);
        if (payload != null) {
          await _handleOpenedFromPayload(payload, source: 'local_cold_start');
        }
      }
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit =
        AndroidInitializationSettings('@drawable/ic_notification');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _local.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  Future<void> _configureForegroundPresentation() async {
    if (!kIsWeb && Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
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
        debugPrint('FCM TOKEN: $token');
      }
      await _registrar?.syncToken(token);
    });
  }

  Future<void> onUserAuthenticated() async {
    if (!_isFcmSupported()) return;

    if (kDebugMode) {
      debugPrint('[FCM] onUserAuthenticated() entered '
          '(bootstrapped=$_bootstrapped)');
    }
    if (!_bootstrapped) await _bootstrap();

    await _refreshAndSyncToken();
  }

  Future<void> onUserLoggedOut() async {
    if (!_isFcmSupported()) return;

    final token = _currentToken;
    await _registrar?.clearToken(token);
  }

  Future<void> _requestPermissionIfNeeded() async {
    if (!_isFcmSupported()) return;

    final prefs = await SharedPreferences.getInstance();
    final alreadyPrompted = prefs.getBool(_prefsPermissionPromptedKey) ?? false;

    if (await _notificationsAlreadyEnabled()) {
      if (kDebugMode) {
        debugPrint('[FCM] Notification permission already granted');
      }
      return;
    }

    if (alreadyPrompted) {
      if (kDebugMode) {
        debugPrint('[FCM] Notifications disabled; not re-prompting');
      }
      return;
    }

    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    } else if (!kIsWeb && Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    await prefs.setBool(_prefsPermissionPromptedKey, true);

    if (kDebugMode) {
      debugPrint('[FCM] Notification permission prompt completed');
    }
  }

  Future<bool> _notificationsAlreadyEnabled() async {
    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await androidPlugin?.areNotificationsEnabled();
      return enabled == true;
    }

    if (!kIsWeb && Platform.isIOS) {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }

    return false;
  }

  Future<void> _refreshAndSyncToken() async {
    try {
      final token = await _messaging.getToken();
      _currentToken = token;
      if (token == null || token.isEmpty) return;
      if (kDebugMode) {
        debugPrint('FCM TOKEN: $token');
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
      debugPrint('[FCM] Notification received');
      debugPrint('[FCM] Message ID: ${message.messageId}');
      debugPrint('[FCM] Title: ${message.notification?.title}');
      debugPrint('[FCM] Body: ${message.notification?.body}');
      debugPrint('[FCM] Data: ${message.data}');
      debugPrint(
        '[FCM] Android imageUrl: ${message.notification?.android?.imageUrl}',
      );
    }

    final saved = await NotificationInboxStore.instance.saveFromRemoteMessage(
      message,
    );

    final title = saved.title;
    final body = saved.body;
    if (title == null && body == null) return;

    if (kIsWeb) return;

    // Foreground Android: FCM does not auto-render Console images — we must
    // download and attach BigPictureStyleInformation on the local notification.
    // Background/terminated: Android system tray shows the FCM notification
    // (including image); this handler must not also call show() there.
    await _showLocalNotification(
      id: saved.id.hashCode,
      title: title,
      body: body,
      imageUrl: extractNotificationImageUrl(message),
      payload: jsonEncode(saved.toTapPayload()),
    );
  }

  Future<void> _showLocalNotification({
    required int id,
    required String? title,
    required String? body,
    required String payload,
    String? imageUrl,
  }) async {
    StyleInformation? styleInformation;
    AndroidBitmap<Object>? largeIcon;

    if (!kIsWeb && Platform.isAndroid && imageUrl != null) {
      final imagePath = await downloadNotificationImage(imageUrl);
      if (imagePath != null) {
        final bitmap = FilePathAndroidBitmap(imagePath);
        largeIcon = bitmap;
        styleInformation = BigPictureStyleInformation(
          bitmap,
          largeIcon: bitmap,
          contentTitle: title,
          summaryText: body,
          hideExpandedLargeIcon: true,
        );
        if (kDebugMode) {
          debugPrint('[FCM] Displaying BigPicture notification');
        }
      } else if (kDebugMode) {
        debugPrint(
          '[FCM] Falling back to plain notification (image unavailable)',
        );
      }
    } else if (kDebugMode && imageUrl == null) {
      debugPrint('[FCM] No notification image URL on message');
    }

    await _local.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          largeIcon: largeIcon,
          styleInformation: styleInformation,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> _onMessageOpenedApp(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint('[FCM] Notification opened from background');
    }
    await _handleOpenedMessage(message, source: 'background');
  }

  Future<void> _handleOpenedMessage(
    RemoteMessage message, {
    required String source,
  }) async {
    if (kDebugMode) {
      debugPrint('[FCM] Processing opened notification ($source)');
      debugPrint('[FCM] Data: ${message.data}');
    }
    final saved = await NotificationInboxStore.instance.saveFromRemoteMessage(
      message,
      markRead: true,
    );
    _emitOpened(saved);
  }

  Future<void> _handleOpenedFromPayload(
    Map<String, dynamic> payload, {
    required String source,
  }) async {
    if (kDebugMode) {
      debugPrint('[FCM] Processing opened notification ($source)');
    }
    final saved = await NotificationInboxStore.instance.saveFromTapPayload(
      payload,
      markRead: true,
    );
    _emitOpened(saved);
  }

  void _emitOpened(AppNotification notification) {
    if (_lastOpenedNotificationId == notification.id) {
      if (kDebugMode) {
        debugPrint('[FCM] Skipping duplicate open id=${notification.id}');
      }
      return;
    }
    _lastOpenedNotificationId = notification.id;
    pendingOpenedNotification = notification;
    _openedController.add(notification);
    if (kDebugMode) {
      debugPrint('[FCM] Navigating to notification id=${notification.id}');
    }
  }

  Future<void> _onLocalNotificationTap(NotificationResponse response) async {
    final payload = _decodeTapPayload(response.payload);
    if (payload == null) return;
    if (kDebugMode) {
      debugPrint('[FCM] Local notification tap');
    }
    await _handleOpenedFromPayload(payload, source: 'foreground_local');
  }

  Map<String, dynamic>? _decodeTapPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

String encodeNotificationData(Map<String, String> data) => jsonEncode(data);
