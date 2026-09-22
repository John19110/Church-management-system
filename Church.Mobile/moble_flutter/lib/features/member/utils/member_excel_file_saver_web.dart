import 'dart:convert';

import 'package:web/web.dart' as web;

/// Triggers a browser download via a temporary object-URL / data URL.
Future<void> saveMemberExcelFile(List<int> bytes, String fileName) async {
  final href =
      'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,${base64Encode(bytes)}';
  final anchor = web.HTMLAnchorElement()
    ..href = href
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
}
