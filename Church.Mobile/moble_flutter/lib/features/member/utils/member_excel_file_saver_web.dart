import 'dart:convert';

import 'package:web/web.dart' as web;

import 'member_excel_file_saver_stub.dart' show MemberExcelSaveResult;

export 'member_excel_file_saver_stub.dart'
    show
        MemberExcelSaveResult,
        beginMemberExcelSave,
        memberExcelSaveCancelled;

Future<MemberExcelSaveResult> saveMemberExcelFile(
  List<int> bytes,
  String fileName, {
  Object? saveHandle,
}) async {
  // Desktop Chrome blocks programmatic downloads after async work. Prepare a
  // data URL and require a dialog button click (fresh user gesture).
  final downloadUrl =
      'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,${base64Encode(bytes)}';
  return MemberExcelSaveResult(
    needsConfirmation: true,
    downloadUrl: downloadUrl,
    fileName: fileName,
  );
}

void confirmMemberExcelDownload(String downloadUrl, String fileName) {
  final anchor = web.HTMLAnchorElement()
    ..href = downloadUrl
    ..download = fileName
    ..rel = 'noopener'
    ..style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
}

void releaseMemberExcelDownloadUrl(String? downloadUrl) {
  // data: URLs do not need revoke.
}
