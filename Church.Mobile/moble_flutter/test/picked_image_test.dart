import 'package:church_app/core/error/app_exception.dart';
import 'package:church_app/core/l10n/app_localizations.dart';
import 'package:church_app/core/media/picked_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveImageUploadFilename', () {
    test('keeps an allowed extension when bytes match', () {
      final name = resolveImageUploadFilename(
        name: 'avatar.png',
        path: r'C:\tmp\avatar.png',
        bytes: const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
      );
      expect(name, 'avatar.png');
    });

    test('rewrites blob names using magic bytes', () {
      final name = resolveImageUploadFilename(
        name: 'blob',
        path: 'blob:https://localhost/abc',
        bytes: const [0xFF, 0xD8, 0xFF, 0xE0],
      );
      expect(name, 'photo.jpg');
    });

    test('replaces a mismatched extension with the detected type', () {
      final name = resolveImageUploadFilename(
        name: 'photo.png',
        path: 'photo.png',
        bytes: const [0xFF, 0xD8, 0xFF, 0xE0],
      );
      expect(name, 'photo.jpg');
    });

    test('keeps .jpeg for jpeg bytes', () {
      final name = resolveImageUploadFilename(
        name: 'scan.jpeg',
        path: '/tmp/scan.jpeg',
        bytes: const [0xFF, 0xD8, 0xFF, 0xE0],
      );
      expect(name, 'scan.jpeg');
    });
  });

  test('PickedImage.toMultipartFile is byte-based and keeps the filename', () {
    final image = PickedImage(
      bytes: Uint8List.fromList(const [0xFF, 0xD8, 0xFF, 0x00]),
      filename: 'photo.jpg',
    );
    final part = image.toMultipartFile();
    expect(part.filename, 'photo.jpg');
    expect(part.length, 4);

    final form = FormData.fromMap({'Image': part});
    expect(form.files.single.key, 'Image');
    expect(form.files.single.value.filename, 'photo.jpg');
  });

  test('MultipartFile dart:io errors map to a user-friendly message', () {
    final en = AppLocalizations.forLocale(const Locale('en'));
    final message = userFriendlyMessage(
      UnsupportedError(
        'MultipartFile is only supported when dart:io is available',
      ),
      en,
    );
    expect(message, en.somethingWentWrongTryAgain);
    expect(message.toLowerCase(), isNot(contains('multipartfile')));
  });
}
