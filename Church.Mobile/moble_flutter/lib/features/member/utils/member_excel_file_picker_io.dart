import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Build stamp for non-web Import picker.
const String kMemberExcelIoPickerStamp = 'MEMBER_EXCEL_IO_PICKER_V2';

/// Picked Excel file for import (bytes + name; no filesystem path required).
class MemberExcelPickedFile {
  const MemberExcelPickedFile({
    required this.bytes,
    required this.fileName,
  });

  final List<int> bytes;
  final String fileName;
}

/// Opens a file picker and returns Excel bytes, or null if cancelled.
Future<MemberExcelPickedFile?> pickMemberExcelFile() async {
  debugPrint('$kMemberExcelIoPickerStamp USED');
  final picked = await FilePicker.platform.pickFiles(
    type: FileType.any,
    withData: true,
    allowMultiple: false,
  );
  if (picked == null || picked.files.isEmpty) return null;

  final file = picked.files.first;
  final bytes = file.bytes;
  final name = file.name;
  if (bytes == null || bytes.isEmpty) return null;
  return MemberExcelPickedFile(bytes: bytes, fileName: name);
}
