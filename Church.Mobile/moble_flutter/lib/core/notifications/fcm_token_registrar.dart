import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../storage/token_storage.dart';

/// Registers the device FCM token with the ASP.NET Core API when available.
///
/// **Backend status:** No device-token endpoint exists yet. This class is a
/// ready hook — [syncToken] is a no-op HTTP call until
/// [AppConstants.deviceTokenEndpoint] is implemented on the API.
///
/// Planned contract (for the Azure API team):
/// - `PUT` or `POST` authenticated endpoint, e.g. `/api/DeviceToken`
/// - Body: `{ "token": "<fcm>", "platform": "android", "deviceId": "..." }`
/// - Associate token with the JWT user (`sub`) server-side
/// - On logout: `DELETE` the token for this device
class FcmTokenRegistrar {
  FcmTokenRegistrar(this._dio);

  final Dio _dio;

  /// Returns true if a sync was attempted against a real endpoint path that is
  /// configured and the user is authenticated. Currently always returns false
  /// after logging once in debug (endpoint not shipped yet).
  Future<bool> syncToken(String fcmToken) async {
    final jwt = TokenStorage.cachedToken ?? await TokenStorage.getToken();
    if (jwt == null || jwt.isEmpty) {
      if (kDebugMode) {
        debugPrint('[FCM] Skip token sync: user not authenticated');
      }
      return false;
    }

    const endpoint = AppConstants.deviceTokenEndpoint;
    if (endpoint.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[FCM] Token ready for backend registration '
          '(endpoint not configured yet). '
          'tokenPrefix=${_tokenPreview(fcmToken)}',
        );
      }
      return false;
    }

    try {
      await _dio.put(
        endpoint,
        data: {
          'token': fcmToken,
          'platform': 'android',
        },
      );
      if (kDebugMode) {
        debugPrint('[FCM] Device token registered with API');
      }
      return true;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] Device token sync failed: ${e.message}');
      }
      return false;
    }
  }

  Future<void> clearToken(String? fcmToken) async {
    const endpoint = AppConstants.deviceTokenEndpoint;
    if (endpoint.isEmpty || fcmToken == null || fcmToken.isEmpty) return;

    final jwt = TokenStorage.cachedToken ?? await TokenStorage.getToken();
    if (jwt == null || jwt.isEmpty) return;

    try {
      await _dio.delete(
        endpoint,
        data: {'token': fcmToken, 'platform': 'android'},
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] Device token clear failed: ${e.message}');
      }
    }
  }

  static String _tokenPreview(String token) {
    if (token.length <= 12) return '***';
    return '${token.substring(0, 8)}…${token.substring(token.length - 4)}';
  }
}
