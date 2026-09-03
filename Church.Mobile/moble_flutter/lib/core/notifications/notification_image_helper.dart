import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Extracts a remote notification image URL from an FCM [RemoteMessage].
///
/// Firebase Console campaigns populate [AndroidNotification.imageUrl] (and the
/// Apple / Web equivalents). Data-payload keys are checked as a fallback for
/// custom / backend-sent messages.
String? extractNotificationImageUrl(RemoteMessage message) {
  final candidates = <String?>[
    message.notification?.android?.imageUrl,
    message.notification?.apple?.imageUrl,
    message.notification?.web?.image,
    message.data['image'],
    message.data['imageUrl'],
    message.data['image_url'],
    message.data['ImageUrl'],
    message.data['picture'],
    message.data['photo'],
  ];

  for (final raw in candidates) {
    final url = raw?.trim();
    if (url == null || url.isEmpty) continue;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      if (kDebugMode) {
        debugPrint('[FCM] Ignoring invalid notification image URL: $url');
      }
      continue;
    }
    if (uri.scheme != 'https' && uri.scheme != 'http') {
      if (kDebugMode) {
        debugPrint('[FCM] Ignoring unsupported image URL scheme: ${uri.scheme}');
      }
      continue;
    }
    return url;
  }
  return null;
}

/// Downloads [imageUrl] into the app temp/cache directory.
///
/// Returns the absolute file path on success, or `null` on any failure.
/// Never throws — callers must fall back to a plain notification.
Future<String?> downloadNotificationImage(String imageUrl) async {
  if (kDebugMode) {
    debugPrint('[FCM] Image URL: $imageUrl');
    debugPrint('[FCM] Downloading notification image...');
  }

  File? file;
  try {
    final uri = Uri.parse(imageUrl);
    // Standalone Dio (no API baseUrl / auth) — image hosts are absolute URLs.
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        responseType: ResponseType.bytes,
        followRedirects: true,
        maxRedirects: 5,
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );

    final response = await dio.getUri<List<int>>(uri);
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      if (kDebugMode) {
        debugPrint('[FCM] Notification image download returned empty body');
      }
      return null;
    }

    final cacheDir = await getTemporaryDirectory();
    final notifDir = Directory('${cacheDir.path}/fcm_notification_images');
    if (!await notifDir.exists()) {
      await notifDir.create(recursive: true);
    }

    final ext = _extensionForBytes(uri, bytes);
    final fileName =
        'fcm_${DateTime.now().millisecondsSinceEpoch}_${bytes.length.hashCode}$ext';
    file = File('${notifDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    // Validate via file API to avoid List<int>/Uint8List mismatch with image 4.9.x.
    final decoded = await img.decodeImageFile(file.path);
    if (decoded == null) {
      if (kDebugMode) {
        debugPrint('[FCM] Notification image could not be decoded');
      }
      await _tryDelete(file);
      return null;
    }

    if (kDebugMode) {
      debugPrint('[FCM] Image downloaded successfully');
      debugPrint('[FCM] Image path: ${file.path}');
    }
    return file.path;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[FCM] Failed to download notification image: $e');
    }
    await _tryDelete(file);
    return null;
  }
}

Future<void> _tryDelete(File? file) async {
  if (file == null) return;
  try {
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {
    // Best-effort cleanup only.
  }
}

String _extensionForBytes(Uri uri, List<int> bytes) {
  final path = uri.path.toLowerCase();
  if (path.endsWith('.png')) return '.png';
  if (path.endsWith('.webp')) return '.webp';
  if (path.endsWith('.gif')) return '.gif';
  if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return '.jpg';

  // Magic-byte fallback when the URL has no (or a misleading) extension.
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return '.png';
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return '.jpg';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return '.webp';
  }
  return '.jpg';
}
