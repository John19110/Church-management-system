import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/utils/api_image_url.dart';

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
    final resolved =
        _loadFailed ? null : resolveApiImageUrl(widget.imageUrl);

    debugLogApiImage(
      context: widget.debugTag ?? 'avatar',
      raw: widget.imageUrl,
      resolved: resolved,
      error: _loadFailed ? 'load_failed' : null,
    );

    if (resolved == null) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: widget.backgroundColor,
        child: widget.placeholder,
      );
    }

    final headers = authImageHeadersForUrl(resolved);

    // Image.network + errorBuilder is reliable on Web; NetworkImage + headers
    // triggers credentialed CORS fetches that fail for public /uploads assets.
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor,
      child: ClipOval(
        child: Image.network(
          resolved,
          width: widget.radius * 2,
          height: widget.radius * 2,
          fit: BoxFit.cover,
          headers: headers,
          errorBuilder: (context, error, stackTrace) {
            if (kDebugMode) {
              debugLogApiImage(
                context: widget.debugTag ?? 'avatar',
                raw: widget.imageUrl,
                resolved: resolved,
                error: error,
              );
            }
            if (!_loadFailed && mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _loadFailed = true);
              });
            }
            return SizedBox(
              width: widget.radius * 2,
              height: widget.radius * 2,
              child: Center(child: widget.placeholder),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: widget.radius * 2,
              height: widget.radius * 2,
              child: Center(
                child: SizedBox(
                  width: widget.radius * 0.6,
                  height: widget.radius * 0.6,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
