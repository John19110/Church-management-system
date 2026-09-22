import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Writes bytes to a temp file and opens it on mobile/desktop.
Future<void> saveMemberExcelFile(List<int> bytes, String fileName) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  await OpenFilex.open(file.path);
}
