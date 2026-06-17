import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/storage/token_storage.dart';

String? resolveApiImageUrl(String? raw) {
  final url = raw?.trim();
  if (url == null || url.isEmpty) return null;
  final lower = url.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) return url;

  // API sometimes returns relative paths like "/images/x.jpg" or "uploads/x.jpg"
  if (url.startsWith('/')) return '${AppConstants.baseUrl}$url';
  return '${AppConstants.baseUrl}/$url';
}

Map<String, String>? authImageHeaders() {
  final token = TokenStorage.cachedToken;
  if (token == null || token.isEmpty) return null;
  return {'Authorization': 'Bearer $token'};
}

class AppNetworkAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Color backgroundColor;
  final Widget? placeholder;
  /// Optional tag for debug logging (e.g. "member-list", "member-detail").
  final String? debugTag;

  const AppNetworkAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 24,
    this.backgroundColor = const Color(0xFFE2E8F0),
    this.placeholder,
    this.debugTag,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = resolveApiImageUrl(imageUrl);
    final size = radius * 2;

    if (kDebugMode && debugTag != null) {
      debugPrint(
        '[AppNetworkAvatar:$debugTag] raw=${imageUrl ?? 'null'} resolved=${resolved ?? 'null'}',
      );
    }

    if (resolved == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: placeholder,
      );
    }

    final headers = authImageHeaders();

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          resolved,
          headers: headers,
          fit: BoxFit.cover,
          // Decorative avatar: keep it OUT of the semantics tree. Otherwise the
          // implicit image semantics node toggles in/out as the image loads,
          // and on Flutter 3.41's new semantics engine that hits a framework
          // dirty-geometry assertion (flutter/flutter #184036/#184226) which,
          // once thrown in flushSemantics, re-throws every frame (infinite loop).
          excludeFromSemantics: true,
          errorBuilder: (_, error, ___) {
            if (kDebugMode && debugTag != null) {
              debugPrint(
                '[AppNetworkAvatar:$debugTag] load failed url=$resolved error=$error',
              );
            }
            return Container(
              color: backgroundColor,
              alignment: Alignment.center,
              child: placeholder,
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: backgroundColor,
              alignment: Alignment.center,
              child: SizedBox(
                width: radius,
                height: radius,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}

