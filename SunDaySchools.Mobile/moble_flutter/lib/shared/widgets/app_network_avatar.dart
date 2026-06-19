import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/storage/token_storage.dart';

String? resolveApiImageUrl(String? raw) {
  final url = raw?.trim();
  if (url == null || url.isEmpty) return null;

  final lower = url.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme && uri.path.isNotEmpty) {
      final path = uri.path;
      // Rebase stored absolute URLs onto the configured API host (emulators/dev).
      if (path.startsWith('/uploads/') || path.startsWith('/images/')) {
        return '${AppConstants.baseUrl}$path';
      }
    }
    return url;
  }

  if (url.startsWith('/')) return '${AppConstants.baseUrl}$url';
  return '${AppConstants.baseUrl}/$url';
}

Map<String, String>? authImageHeaders() {
  final token = TokenStorage.cachedToken;
  if (token == null || token.isEmpty) return null;
  return {'Authorization': 'Bearer $token'};
}

class AppNetworkAvatar extends StatefulWidget {
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
  State<AppNetworkAvatar> createState() => _AppNetworkAvatarState();
}

class _AppNetworkAvatarState extends State<AppNetworkAvatar> {
  bool _loadFailed = false;

  @override
  void didUpdateWidget(covariant AppNetworkAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadFailed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _loadFailed ? null : resolveApiImageUrl(widget.imageUrl);

    if (kDebugMode && widget.debugTag != null) {
      debugPrint(
        '[AppNetworkAvatar:${widget.debugTag}] raw=${widget.imageUrl ?? 'null'} '
        'resolved=${resolved ?? 'null'} failed=$_loadFailed',
      );
    }

    // Do not pass [placeholder] as [CircleAvatar.child] when an image is set —
    // the child paints on top of [backgroundImage] and hides the photo.
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: widget.radius,
        backgroundColor: widget.backgroundColor,
        backgroundImage: resolved != null
            ? NetworkImage(resolved, headers: authImageHeaders())
            : null,
        onBackgroundImageError: resolved == null
            ? null
            : (_, error) {
                if (kDebugMode && widget.debugTag != null) {
                  debugPrint(
                    '[AppNetworkAvatar:${widget.debugTag}] load failed '
                    'url=$resolved error=$error',
                  );
                }
                if (mounted) setState(() => _loadFailed = true);
              },
        child: resolved == null ? widget.placeholder : null,
      ),
    );
  }
}
