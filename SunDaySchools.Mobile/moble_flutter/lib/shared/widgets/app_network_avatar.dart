import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

String? resolveApiImageUrl(String? raw) {
  final url = raw?.trim();
  if (url == null || url.isEmpty) return null;
  final lower = url.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) return url;

  // API sometimes returns relative paths like "/uploads/x.jpg" or "uploads/x.jpg"
  if (url.startsWith('/')) return '${AppConstants.baseUrl}$url';
  return '${AppConstants.baseUrl}/$url';
}

class AppNetworkAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Color backgroundColor;
  final Widget? placeholder;

  const AppNetworkAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 24,
    this.backgroundColor = const Color(0xFFE2E8F0),
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = resolveApiImageUrl(imageUrl);
    final size = radius * 2;

    if (resolved == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: placeholder,
      );
    }

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          resolved,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: backgroundColor,
            alignment: Alignment.center,
            child: placeholder,
          ),
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

