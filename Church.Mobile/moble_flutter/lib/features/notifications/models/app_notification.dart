import 'package:firebase_messaging/firebase_messaging.dart';

/// In-app notification shown on the existing Notifications screen.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.receivedAt,
    this.title,
    this.body,
    this.type,
    this.data = const {},
    this.isRead = false,
  });

  final String id;
  final String? title;
  final String? body;
  final String? type;
  final Map<String, String> data;
  final DateTime receivedAt;
  final bool isRead;

  String? get meetingId => data['meetingId'];
  String? get announcementId => data['announcementId'];

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    Map<String, String>? data,
    DateTime? receivedAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      receivedAt: receivedAt ?? this.receivedAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'receivedAt': receivedAt.toUtc().toIso8601String(),
        'isRead': isRead,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final data = <String, String>{};
    if (rawData is Map) {
      for (final entry in rawData.entries) {
        if (entry.value != null) {
          data[entry.key.toString()] = entry.value.toString();
        }
      }
    }
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String?,
      body: json['body'] as String?,
      type: json['type'] as String?,
      data: data,
      receivedAt: DateTime.tryParse(json['receivedAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  /// Build from FCM [RemoteMessage] (notification and/or data payload).
  factory AppNotification.fromRemoteMessage(
    RemoteMessage message, {
    bool isRead = false,
  }) {
    final data = <String, String>{};
    for (final entry in message.data.entries) {
      data[entry.key] = entry.value.toString();
    }
    final title = message.notification?.title ?? data['title'];
    final body = message.notification?.body ?? data['body'];
    return AppNotification(
      id: resolveNotificationId(message),
      title: title,
      body: body,
      type: data['type'],
      data: data,
      receivedAt: message.sentTime?.toUtc() ?? DateTime.now().toUtc(),
      isRead: isRead,
    );
  }

  /// Payload for [flutter_local_notifications] tap handling.
  Map<String, dynamic> toTapPayload() => {
        'id': id,
        if (title != null) 'title': title,
        if (body != null) 'body': body,
        if (type != null) 'type': type,
        ...data,
      };

  factory AppNotification.fromTapPayload(Map<String, dynamic> raw) {
    final data = <String, String>{};
    String? title;
    String? body;
    String? type;
    String? id;

    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final value = entry.value?.toString();
      if (value == null) continue;
      switch (key) {
        case 'id':
          id = value;
        case 'title':
          title = value;
        case 'body':
          body = value;
        case 'type':
          type = value;
        default:
          data[key] = value;
      }
    }

    return AppNotification(
      id: id ?? 'tap_${title.hashCode}_${body.hashCode}',
      title: title,
      body: body,
      type: type,
      data: data,
      receivedAt: DateTime.now().toUtc(),
      isRead: true,
    );
  }
}

/// Stable id for deduplication across foreground/background/tap handlers.
String resolveNotificationId(RemoteMessage message) {
  final messageId = message.messageId;
  if (messageId != null && messageId.isNotEmpty) {
    return messageId;
  }
  final dataId =
      message.data['notificationId'] ?? message.data['id'] ?? message.data['Id'];
  if (dataId != null && dataId.toString().isNotEmpty) {
    return dataId.toString();
  }
  final sent =
      message.sentTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
  final title = message.notification?.title ?? message.data['title'] ?? '';
  final body = message.notification?.body ?? message.data['body'] ?? '';
  return 'gen_${title.hashCode}_${body.hashCode}_$sent';
}
