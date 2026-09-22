// Web-only Import picker. Never imports package:file_picker.
// ignore_for_file: avoid_web_libraries_in_flutter, uri_does_not_exist

import 'dart:async';
import 'dart:js_util' as jsu;

import 'package:web/web.dart' as web;

/// Build stamp — must appear in the browser console on Import Members.
const String kMemberExcelWebPickerStamp = 'MEMBER_EXCEL_WEB_PICKER_V3';

/// Picked Excel file for import (bytes + name; no filesystem path).
class MemberExcelPickedFile {
  const MemberExcelPickedFile({
    required this.bytes,
    required this.fileName,
  });

  final List<int> bytes;
  final String fileName;
}

void _log(String message) {
  // ignore: avoid_print
  print(message);
  try {
    final console = jsu.getProperty(jsu.globalThis, 'console');
    jsu.callMethod(console, 'log', [message]);
  } catch (_) {}
}

List<int> _bytesFromArrayBuffer(Object arrayBuffer) {
  final uint8 = jsu.callConstructor(
    jsu.getProperty(jsu.globalThis, 'Uint8Array'),
    [arrayBuffer],
  );
  final length = jsu.getProperty(uint8, 'length') as int;
  return List<int>.generate(length, (i) => jsu.getProperty(uint8, i) as int);
}

/// Opens the browser file dialog and returns selected Excel bytes.
///
/// [upload.click] must run synchronously inside the button's user-gesture
/// stack. Any `await` before click breaks Edge desktop and Chrome mobile
/// (desktop Chrome often still allows it).
Future<MemberExcelPickedFile?> pickMemberExcelFile() {
  _log('$kMemberExcelWebPickerStamp USED');

  final upload = web.HTMLInputElement()
    ..type = 'file'
    // Keep accept short — long MIME lists break some mobile browsers.
    ..accept = '.xlsx,.xls'
    ..multiple = false;

  // Off-screen but still "visible" to the UA. Avoid display:none and
  // pointer-events:none — both can block click() on Edge / mobile Chrome.
  upload.style
    ..position = 'fixed'
    ..left = '0'
    ..top = '0'
    ..width = '1px'
    ..height = '1px'
    ..opacity = '0'
    ..overflow = 'hidden'
    ..zIndex = '2147483647';

  web.document.body?.appendChild(upload);

  final completer = Completer<MemberExcelPickedFile?>();
  var settled = false;

  void finish(MemberExcelPickedFile? value) {
    if (settled) return;
    settled = true;
    try {
      upload.remove();
    } catch (_) {}
    if (!completer.isCompleted) completer.complete(value);
  }

  upload.onChange.listen((_) {
    final files = upload.files;
    if (files == null || files.length == 0) {
      _log('$kMemberExcelWebPickerStamp change: empty');
      finish(null);
      return;
    }
    final file = files.item(0);
    if (file == null) {
      finish(null);
      return;
    }

    _log('$kMemberExcelWebPickerStamp selected=${file.name} size=${file.size}');

    final reader = web.FileReader();
    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result == null) {
        finish(null);
        return;
      }
      try {
        final bytes = _bytesFromArrayBuffer(result);
        _log('$kMemberExcelWebPickerStamp bytes=${bytes.length}');
        if (bytes.isEmpty) {
          finish(null);
          return;
        }
        finish(MemberExcelPickedFile(bytes: bytes, fileName: file.name));
      } catch (e) {
        _log('$kMemberExcelWebPickerStamp read-error=$e');
        finish(null);
      }
    });
    reader.readAsArrayBuffer(file);
  });

  // Optional cancel (Chrome 113+ / Edge). Must not block click().
  try {
    jsu.callMethod(upload, 'addEventListener', [
      'cancel',
      jsu.allowInterop((Object _) {
        _log('$kMemberExcelWebPickerStamp cancelled');
        finish(null);
      }),
    ]);
  } catch (_) {}

  // CRITICAL: click in the same synchronous turn as the button handler.
  upload.click();
  _log('$kMemberExcelWebPickerStamp dialog-opened');

  return completer.future;
}
