import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';

import '../error/app_exception.dart';

const _allowedExtensions = {'.jpg', '.jpeg', '.png', '.webp'};

/// Cross-platform selected image. Safe on Flutter Web and Android.
///
/// Web cannot use `dart:io` [File] or Dio [MultipartFile.fromFile]. Bytes from
/// [XFile.readAsBytes] work on every platform Dio supports.
class PickedImage {
  const PickedImage({
    required this.bytes,
    required this.filename,
  });

  final Uint8List bytes;
  final String filename;

  int get lengthInBytes => bytes.length;

  MemoryImage get memoryImage => MemoryImage(bytes);

  /// Multipart part named by the caller (ASP.NET expects field `Image`).
  MultipartFile toMultipartFile() {
    return MultipartFile.fromBytes(
      bytes,
      filename: filename,
      contentType: _mediaTypeForFilename(filename),
    );
  }
}

/// Opens the gallery picker. Returns `null` when the user cancels.
Future<PickedImage?> pickImageFromGallery({int imageQuality = 80}) async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: imageQuality,
  );
  if (picked == null) return null;

  final bytes = await picked.readAsBytes();
  if (bytes.isEmpty) {
    if (kDebugMode) {
      debugPrint(
        'PickedImage: empty bytes from ${picked.name} path=${picked.path}',
      );
    }
    throw const AppException('The selected image could not be read.');
  }

  final filename = resolveImageUploadFilename(
    name: picked.name,
    path: picked.path,
    bytes: bytes,
  );

  if (kDebugMode) {
    debugPrint(
      'PickedImage: $filename (${bytes.length} bytes, mime=${picked.mimeType})',
    );
  }

  return PickedImage(bytes: bytes, filename: filename);
}

/// Chooses a filename with an extension the ASP.NET [ImageUploadValidator] accepts.
@visibleForTesting
String resolveImageUploadFilename({
  required String? name,
  required String? path,
  required List<int> bytes,
}) {
  var raw = (name ?? '').trim();
  if (raw.isEmpty || raw.toLowerCase() == 'blob') {
    final pathValue = path ?? '';
    final fromPath = pathValue.replaceAll('\\', '/').split('/').last.trim();
    if (_isFilesystemFileName(pathValue, fromPath)) {
      raw = fromPath;
    }
  }

  final detected = extensionFromImageBytes(bytes);
  if (detected != null && !_extensionMatchesDetected(raw, detected)) {
    final stem = _stemOf(raw);
    return '${stem.isEmpty ? 'photo' : stem}$detected';
  }

  if (_hasAllowedExtension(raw)) return raw;

  return '${_stemOf(raw).isEmpty ? 'photo' : _stemOf(raw)}${detected ?? '.jpg'}';
}

@visibleForTesting
String? extensionFromImageBytes(List<int> bytes) {
  if (_startsWith(bytes, const [0xFF, 0xD8, 0xFF])) return '.jpg';
  if (_startsWith(bytes, const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return '.png';
  }
  if (_startsWith(bytes, const [0x52, 0x49, 0x46, 0x46])) return '.webp';
  return null;
}

bool _isFilesystemFileName(String path, String fromPath) {
  if (fromPath.isEmpty || fromPath.toLowerCase() == 'blob') return false;
  final lower = path.toLowerCase();
  if (lower.startsWith('blob:') ||
      lower.startsWith('http:') ||
      lower.startsWith('https:') ||
      lower.startsWith('data:')) {
    return false;
  }
  return true;
}

bool _startsWith(List<int> bytes, List<int> signature) {
  if (bytes.length < signature.length) return false;
  for (var i = 0; i < signature.length; i++) {
    if (bytes[i] != signature[i]) return false;
  }
  return true;
}

String _extensionOf(String name) {
  final index = name.lastIndexOf('.');
  if (index < 0 || index == name.length - 1) return '';
  return name.substring(index).toLowerCase();
}

String _stemOf(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty || trimmed.toLowerCase() == 'blob') return '';
  final index = trimmed.lastIndexOf('.');
  if (index <= 0) return trimmed;
  return trimmed.substring(0, index);
}

bool _hasAllowedExtension(String name) =>
    _allowedExtensions.contains(_extensionOf(name));

bool _extensionMatchesDetected(String name, String detected) {
  final ext = _extensionOf(name);
  if (detected == '.jpg') return ext == '.jpg' || ext == '.jpeg';
  return ext == detected;
}

DioMediaType? _mediaTypeForFilename(String filename) {
  switch (_extensionOf(filename)) {
    case '.jpg':
    case '.jpeg':
      return DioMediaType('image', 'jpeg');
    case '.png':
      return DioMediaType('image', 'png');
    case '.webp':
      return DioMediaType('image', 'webp');
    default:
      return null;
  }
}
