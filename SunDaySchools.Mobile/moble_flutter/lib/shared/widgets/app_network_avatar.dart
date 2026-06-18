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

  Widget _placeholderBox() {
    return Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: placeholder,
    );
  }

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
      return ExcludeSemantics(
        child: CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor,
          child: placeholder,
        ),
      );
    }

    // Decorative avatars must not participate in semantics. Keep a STABLE widget
    // tree (Stack + opacity fade) — loadingBuilder child swaps inside a ListView
    // leave parentData dirty during RenderViewportBase.visitChildrenForSemantics
    // (Flutter 3.41: '!semantics.parentDataDirty' / geometry! null).
    return ExcludeSemantics(
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _placeholderBox(),
              Image.network(
                resolved,
                headers: authImageHeaders(),
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                gaplessPlayback: true,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  final visible =
                      frame != null || wasSynchronouslyLoaded;
                  return Opacity(opacity: visible ? 1 : 0, child: child);
                },
                errorBuilder: (_, error, ___) {
                  if (kDebugMode && debugTag != null) {
                    debugPrint(
                      '[AppNetworkAvatar:$debugTag] load failed url=$resolved error=$error',
                    );
                  }
                  // Placeholder underneath stays visible; do not swap subtree.
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
