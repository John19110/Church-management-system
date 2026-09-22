import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'member_excel_file_saver_stub.dart' show MemberExcelSaveResult;

export 'member_excel_file_saver_stub.dart'
    show MemberExcelSaveResult, memberExcelSaveCancelled;

Future<Object?> beginMemberExcelSave({required String suggestedFileName}) async =>
    null;

Future<MemberExcelSaveResult> saveMemberExcelFile(
  List<int> bytes,
  String fileName, {
  Object? saveHandle,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  await OpenFilex.open(file.path);
  return MemberExcelSaveResult(
    needsConfirmation: false,
    fileName: fileName,
  );
}

void confirmMemberExcelDownload(String downloadUrl, String fileName) {}

void releaseMemberExcelDownloadUrl(String? downloadUrl) {}
