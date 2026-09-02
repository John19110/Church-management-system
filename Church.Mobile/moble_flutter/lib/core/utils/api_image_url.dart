import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

/// Public static upload paths served by ASP.NET [UseStaticFiles] (no JWT required).
bool isPublicApiImagePath(String path) {
  final normalized = path.toLowerCase();
  return normalized.startsWith('/uploads/') ||
      normalized.startsWith('/images/') ||
      normalized.startsWith('uploads/') ||
      normalized.startsWith('images/');
}

/// Resolves API image references (relative, absolute, or legacy file names) to a
/// full HTTPS URL using [AppConstants.baseUrl].
String? resolveApiImageUrl(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;

  if (value.contains('://')) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return null;

    final path = uri.path;
    if (path.isEmpty) return null;

    // Rebase stored absolute URLs (dev emulator, old host) onto the active API host.
    if (isPublicApiImagePath(path)) {
      return _joinBaseUrl(path);
    }

    // Upgrade http→https when the configured API base is HTTPS (mixed-content safe).
    if (uri.scheme == 'http' && AppConstants.baseUrl.startsWith('https://')) {
      return uri.replace(scheme: 'https').toString();
    }

    return value;
  }

  if (value.startsWith('/')) {
    return _joinBaseUrl(value);
  }

  if (isPublicApiImagePath(value)) {
    return _joinBaseUrl('/$value');
  }

  // Bare file name from legacy rows — registration photos live under /images/.
  return _joinBaseUrl('/images/$value');
}

String _joinBaseUrl(String path) {
  final base = AppConstants.baseUrl.replaceAll(RegExp(r'/+$'), '');
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  return '$base$normalizedPath';
}

/// Public static files must not send JWT headers on Web (triggers CORS fetch).
Map<String, String>? authImageHeadersForUrl(String? resolvedUrl) {
  if (resolvedUrl == null || resolvedUrl.isEmpty) return null;

  final uri = Uri.tryParse(resolvedUrl);
  if (uri == null) return null;

  if (isPublicApiImagePath(uri.path)) {
    return null;
  }

  // Web cannot reliably load cross-origin images with custom Authorization headers.
  if (kIsWeb) return null;

  return null; // Reserved for future protected image endpoints.
}

void debugLogApiImage({
  required String context,
  String? raw,
  String? resolved,
  Object? error,
}) {
  if (!kDebugMode) return;
  debugPrint(
    '[ApiImage:$context] platform=${kIsWeb ? 'web' : 'mobile'} '
    'baseUrl=${AppConstants.baseUrl} raw=${raw ?? 'null'} '
    'resolved=${resolved ?? 'null'}'
    '${error != null ? ' error=$error' : ''}',
  );
}
