import 'package:flutter/foundation.dart';

/// Resolves a displayable image reference for a member from API fields.
String? memberDisplayImageUrl({
  String? imageUrl,
  String? imageFileName,
}) {
  final rawUrl = imageUrl?.trim();
  if (rawUrl != null && rawUrl.isNotEmpty) {
    return rawUrl;
  }

  final fileName = imageFileName?.trim();
  if (fileName == null || fileName.isEmpty) {
    return null;
  }

  if (fileName.contains('://')) {
    return fileName;
  }
  if (fileName.startsWith('/')) {
    return fileName;
  }
  if (fileName.startsWith('members/')) {
    return '/uploads/$fileName';
  }
  if (fileName.startsWith('servants/')) {
    return '/uploads/$fileName';
  }

  return '/images/$fileName';
}

/// Logs image resolution in debug builds (temporary diagnostics).
void debugLogMemberImage({
  required String context,
  String? imageFileName,
  String? imageUrl,
  String? displayUrl,
  String? resolvedUrl,
  Object? error,
}) {
  if (!kDebugMode) return;
  debugPrint(
    '[MemberImage:$context] fileName=${imageFileName ?? 'null'} '
    'imageUrl=${imageUrl ?? 'null'} '
    'display=${displayUrl ?? 'null'} '
    'resolved=${resolvedUrl ?? 'null'}'
    '${error != null ? ' error=$error' : ''}',
  );
}

