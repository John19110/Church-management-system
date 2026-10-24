// Web-only Contact Picker (navigator.contacts.select).
// ignore_for_file: avoid_web_libraries_in_flutter, uri_does_not_exist

import 'dart:js_util' as jsu;

import 'package:web/web.dart' as web;

import 'web_contact_picker_stub.dart' show WebContactPickResult;

export 'web_contact_picker_stub.dart'
    show WebContactPickKind, WebContactPickResult;

/// Synchronous feature detection — must not await, so a following [select]
/// call stays inside the user-gesture / transient activation window.
bool isWebContactPickerSupported() {
  try {
    if (!web.window.isSecureContext) return false;
    final navigator = jsu.getProperty(jsu.globalThis, 'navigator');
    if (navigator == null) return false;
    final contacts = jsu.getProperty(navigator, 'contacts');
    if (contacts == null) return false;
    return jsu.getProperty(contacts, 'select') != null;
  } catch (_) {
    return false;
  }
}

/// Opens the browser Contact Picker and returns telephone numbers.
///
/// [select] is invoked immediately (no prior await) so user activation is kept.
Future<WebContactPickResult> pickWebContactPhones() async {
  if (!isWebContactPickerSupported()) {
    return WebContactPickResult.unsupported();
  }

  try {
    final contacts = jsu.getProperty(
      jsu.getProperty(jsu.globalThis, 'navigator'),
      'contacts',
    );

    // Properties + options are prepared without awaiting.
    final promise = jsu.callMethod(contacts, 'select', [
      jsu.jsify(['tel', 'name']),
      jsu.jsify({'multiple': false}),
    ]);

    final selected = await jsu.promiseToFuture<Object>(promise);
    final phones = _extractPhones(selected);
    if (phones.isEmpty) {
      // Spec: empty array when the user cancels; also covers contacts with no tel.
      final contactCount = _jsLength(selected);
      if (contactCount == 0) return WebContactPickResult.cancelled();
      return WebContactPickResult.noPhone();
    }
    return WebContactPickResult.success(phones);
  } catch (e) {
    // AbortError = user dismissed the picker. Other failures (SecurityError,
    // NotAllowedError, expired user activation, etc.) surface as failed.
    if (_isAbort(e)) return WebContactPickResult.cancelled();
    return WebContactPickResult.failed();
  }
}

List<String> _extractPhones(Object selected) {
  final length = _jsLength(selected);
  final phones = <String>[];
  for (var i = 0; i < length; i++) {
    final contact = jsu.getProperty(selected, i);
    if (contact == null) continue;
    final tels = jsu.getProperty(contact, 'tel');
    if (tels == null) continue;
    final telCount = _jsLength(tels);
    for (var t = 0; t < telCount; t++) {
      final raw = jsu.getProperty(tels, t);
      final number = raw?.toString().trim() ?? '';
      if (number.isNotEmpty) phones.add(number);
    }
  }
  return phones;
}

int _jsLength(Object? jsArray) {
  if (jsArray == null) return 0;
  try {
    final length = jsu.getProperty(jsArray, 'length');
    if (length is num) return length.toInt();
  } catch (_) {}
  return 0;
}

bool _isAbort(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('aborterror') ||
      text.contains('abort') ||
      text.contains('the user aborted');
}
