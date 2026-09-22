/// Result of preparing an Excel file for the user to keep.
class MemberExcelSaveResult {
  /// False when the file was already written/opened (mobile/desktop IO).
  final bool needsConfirmation;

  /// Browser URL (blob: or data:) used when [needsConfirmation] is true.
  final String? downloadUrl;

  final String fileName;

  const MemberExcelSaveResult({
    required this.needsConfirmation,
    required this.fileName,
    this.downloadUrl,
  });
}

/// Starts a save that must run inside the button click (user gesture).
/// Web returns null; confirmation dialog supplies the gesture after the API.
Future<Object?> beginMemberExcelSave({required String suggestedFileName}) =>
    Future<Object?>.value(null);

/// Sentinel used when the user cancels a native Save dialog (unused on web).
const Object memberExcelSaveCancelled = Object();


/// Finishes a save started with [beginMemberExcelSave], or prepares a
/// confirmation download when no handle was obtained.
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
