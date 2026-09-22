// Web-only: do not use FilePicker.platform — its static late `_instance` is
// often unset in Flutter Web release builds (desktop Chrome/Edge).
// ignore_for_file: avoid_web_libraries_in_flutter, uri_does_not_exist

import 'dart:async';
import 'dart:js_util' as jsu;

import 'package:web/web.dart' as web;

/// Picked Excel file for import (bytes + name; no filesystem path).
class MemberExcelPickedFile {
  const MemberExcelPickedFile({
    required this.bytes,
    required this.fileName,
  });

  final List<int> bytes;
  final String fileName;
}

List<int> _bytesFromArrayBuffer(Object arrayBuffer) {
  final uint8 = jsu.callConstructor(
    jsu.getProperty(jsu.globalThis, 'Uint8Array'),
    [arrayBuffer],
  );
  final length = jsu.getProperty(uint8, 'length') as int;
  return List<int>.generate(length, (i) => jsu.getProperty(uint8, i) as int);
}

/// Opens the browser file picker and reads the selected file as bytes.
Future<MemberExcelPickedFile?> pickMemberExcelFile() async {
  final upload = web.HTMLInputElement()
    ..type = 'file'
    ..accept =
        '.xlsx,.xls,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.ms-excel'
    ..multiple = false
    ..style.display = 'none';

  web.document.body?.appendChild(upload);

  final completer = Completer<MemberExcelPickedFile?>();
  var settled = false;
  var changeStarted = false;

  void finish(MemberExcelPickedFile? value) {
    if (settled) return;
    settled = true;
    upload.remove();
    if (!completer.isCompleted) completer.complete(value);
  }

  upload.onChange.listen((_) {
    changeStarted = true;
    final files = upload.files;
    if (files == null || files.length == 0) {
      finish(null);
      return;
    }
    final file = files.item(0);
    if (file == null) {
      finish(null);
      return;
    }

    final reader = web.FileReader();
    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result == null) {
        finish(null);
        return;
      }
      try {
        final bytes = _bytesFromArrayBuffer(result);
        if (bytes.isEmpty) {
          finish(null);
          return;
        }
        finish(MemberExcelPickedFile(bytes: bytes, fileName: file.name));
      } catch (_) {
        finish(null);
      }
    });
    reader.readAsArrayBuffer(file);
  });

  // Desktop: dismiss/cancel without a change event.
  final focusSub = web.EventStreamProviders.focusEvent.forTarget(web.window).listen((_) {
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!settled && !changeStarted) finish(null);
    });
  });

  upload.click();
  final picked = await completer.future;
  await focusSub.cancel();
  return picked;
}
