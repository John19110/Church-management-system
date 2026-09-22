/// Stub — selected only when neither IO nor web libraries apply.
const String kMemberExcelStubPickerStamp = 'MEMBER_EXCEL_STUB_PICKER';

class MemberExcelPickedFile {
  const MemberExcelPickedFile({
    required this.bytes,
    required this.fileName,
  });

  final List<int> bytes;
  final String fileName;
}

Future<MemberExcelPickedFile?> pickMemberExcelFile() async {
  throw UnsupportedError('Excel file picking is not supported on this platform.');
}
