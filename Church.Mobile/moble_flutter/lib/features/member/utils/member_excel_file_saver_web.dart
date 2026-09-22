// Web-only implementation selected via conditional import.
// ignore_for_file: avoid_web_libraries_in_flutter, uri_does_not_exist

import 'dart:js_util' as jsu;

import 'package:web/web.dart' as web;

import 'member_excel_file_saver_stub.dart'
    show MemberExcelSaveResult, memberExcelSaveCancelled;

export 'member_excel_file_saver_stub.dart'
    show MemberExcelSaveResult, memberExcelSaveCancelled;

/// Opens Chromium/Edge Save dialog during the button click (user gesture).
Future<Object?> beginMemberExcelSave({required String suggestedFileName}) async {
  final picker = jsu.getProperty(jsu.globalThis, 'showSaveFilePicker');
  if (picker == null) return null;
  try {
    final handle = await jsu.promiseToFuture<Object>(
      jsu.callMethod(
        jsu.globalThis,
        'showSaveFilePicker',
        [
          jsu.jsify({'suggestedName': suggestedFileName}),
        ],
      ),
    );
    return handle;
  } catch (e) {
    final message = e.toString().toLowerCase();
    if (message.contains('aborterror') || message.contains('abort')) {
      return memberExcelSaveCancelled;
    }
    return null;
  }
}

/// Builds a real binary Blob (not a data: URL). Desktop Chrome throws on long
/// base64 hrefs; blob: object URLs stay short and work after a confirm click.
Object _excelBlob(List<int> bytes) {
  final uint8Ctor = jsu.getProperty(jsu.globalThis, 'Uint8Array');
  final jsBytes = jsu.callConstructor(uint8Ctor, [bytes.length]);
  for (var i = 0; i < bytes.length; i++) {
    jsu.setProperty(jsBytes, i, bytes[i]);
  }
  return jsu.callConstructor(
    jsu.getProperty(jsu.globalThis, 'Blob'),
    [
      [jsBytes],
      jsu.jsify({
        'type':
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      }),
    ],
  );
}

void _clickDownload(String objectUrl, String fileName) {
  final anchor = web.HTMLAnchorElement()
    ..href = objectUrl
    ..download = fileName
    ..rel = 'noopener'
    ..type =
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    ..style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
}

Future<MemberExcelSaveResult> saveMemberExcelFile(
  List<int> bytes,
  String fileName, {
  Object? saveHandle,
}) async {
  final blob = _excelBlob(bytes);

  if (saveHandle != null) {
    final writable = await jsu.promiseToFuture(
      jsu.callMethod(saveHandle, 'createWritable', const []),
    );
    await jsu.promiseToFuture(jsu.callMethod(writable, 'write', [blob]));
    await jsu.promiseToFuture(jsu.callMethod(writable, 'close', const []));
    return MemberExcelSaveResult(
      needsConfirmation: false,
      fileName: fileName,
    );
  }

  final objectUrl = jsu.callMethod(
    jsu.getProperty(jsu.globalThis, 'URL'),
    'createObjectURL',
    [blob],
  ) as String;

  // Mobile web often accepts this after async. Desktop may need the dialog.
  _clickDownload(objectUrl, fileName);
  return MemberExcelSaveResult(
    needsConfirmation: true,
    downloadUrl: objectUrl,
    fileName: fileName,
  );
}

void confirmMemberExcelDownload(String downloadUrl, String fileName) {
  _clickDownload(downloadUrl, fileName);
}

void releaseMemberExcelDownloadUrl(String? downloadUrl) {
  if (downloadUrl == null || downloadUrl.isEmpty) return;
  if (downloadUrl.startsWith('blob:')) {
    jsu.callMethod(
      jsu.getProperty(jsu.globalThis, 'URL'),
      'revokeObjectURL',
      [downloadUrl],
    );
  }
}
