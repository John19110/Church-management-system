import 'dart:convert';

/// Parsed FCM / local-notification data for future deep-link navigation.
///
/// Expected data keys (string values from FCM `data` map):
/// - `type` — e.g. `meeting`, `announcement`, `church`, `broadcast`
/// - `meetingId`, `announcementId`, `churchId`, etc. as needed
class NotificationPayload {
  const NotificationPayload({
    required this.type,
    required this.data,
  });

  final String? type;
  final Map<String, String> data;

  String? get meetingId => data['meetingId'];
  String? get announcementId => data['announcementId'];
  String? get churchId => data['churchId'];

  factory NotificationPayload.fromData(Map<String, dynamic> raw) {
    final data = <String, String>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value == null) continue;
      data[entry.key] = value.toString();
    }
    return NotificationPayload(
      type: data['type'],
      data: data,
    );
  }

  /// Encode for [flutter_local_notifications] payload string.
  String toPayloadString() => jsonEncode(data);

  static NotificationPayload? tryParsePayloadString(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return NotificationPayload.fromData(decoded);
      }
      if (decoded is Map) {
        return NotificationPayload.fromData(
          decoded.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
    } catch (_) {
      // Non-JSON payloads are ignored for navigation.
    }
    return null;
  }
}
