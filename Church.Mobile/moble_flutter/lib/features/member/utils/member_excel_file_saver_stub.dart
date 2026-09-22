/// Result of preparing an Excel file for the user to keep.
class MemberExcelSaveResult {
  /// False when the file was already written/opened (IO or native Save picker).
  final bool needsConfirmation;

  /// Browser blob: URL used when [needsConfirmation] is true.
  final String? downloadUrl;

  final String fileName;

  const MemberExcelSaveResult({
    required this.needsConfirmation,
    required this.fileName,
    this.downloadUrl,
  });
}

/// Sentinel when the user cancels a native Save dialog.
const Object memberExcelSaveCancelled = Object();

/// Starts a save during the button click (user gesture). Web Chromium opens
/// the native Save dialog; other platforms return null.
Future<Object?> beginMemberExcelSave({required String suggestedFileName}) =>
    Future<Object?>.value(null);

/// Writes/opens bytes, or prepares a blob: URL for a confirmation click.
Future<MemberExcelSaveResult> saveMemberExcelFile(
  List<int> bytes,
  String fileName, {
  Object? saveHandle,
}) {
  throw UnsupportedError('Saving Excel files is not supported on this platform.');
}

/// Triggers a browser download from a previously prepared [downloadUrl].
/// Must run inside a fresh user gesture (e.g. dialog button).
void confirmMemberExcelDownload(String downloadUrl, String fileName) {}

/// Releases a blob: URL created for confirmation download.
void releaseMemberExcelDownloadUrl(String? downloadUrl) {}
