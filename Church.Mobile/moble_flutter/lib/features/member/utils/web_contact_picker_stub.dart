/// Result of attempting to open the browser Contact Picker API.
enum WebContactPickKind {
  /// `navigator.contacts.select` is missing, insecure context, or blocked.
  unsupported,

  /// User dismissed the picker (empty result or AbortError).
  cancelled,

  /// Picker returned a contact with no usable telephone numbers.
  noPhone,

  /// At least one telephone number was selected.
  success,

  /// Unexpected security / runtime failure after the API was detected.
  failed,
}

/// Outcome of [pickWebContactPhones].
class WebContactPickResult {
  const WebContactPickResult._(this.kind, [this.phones = const []]);

  final WebContactPickKind kind;
  final List<String> phones;

  factory WebContactPickResult.unsupported() =>
      const WebContactPickResult._(WebContactPickKind.unsupported);

  factory WebContactPickResult.cancelled() =>
      const WebContactPickResult._(WebContactPickKind.cancelled);

  factory WebContactPickResult.noPhone() =>
      const WebContactPickResult._(WebContactPickKind.noPhone);

  factory WebContactPickResult.success(List<String> phones) =>
      WebContactPickResult._(WebContactPickKind.success, phones);

  factory WebContactPickResult.failed() =>
      const WebContactPickResult._(WebContactPickKind.failed);

  bool get isSuccess => kind == WebContactPickKind.success;
}

/// Non-web stub — Contact Picker API is a browser-only feature.
bool isWebContactPickerSupported() => false;

/// Non-web stub.
Future<WebContactPickResult> pickWebContactPhones() async =>
    WebContactPickResult.unsupported();
