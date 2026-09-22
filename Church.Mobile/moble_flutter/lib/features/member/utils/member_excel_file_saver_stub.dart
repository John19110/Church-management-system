/// Fallback when neither IO nor web libraries are available.
Future<void> saveMemberExcelFile(List<int> bytes, String fileName) {
  throw UnsupportedError('Saving Excel files is not supported on this platform.');
}
