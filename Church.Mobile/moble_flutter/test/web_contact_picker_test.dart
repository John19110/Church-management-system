import 'package:church_app/features/member/utils/web_contact_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebContactPickResult', () {
    test('success carries phones', () {
      final result = WebContactPickResult.success(const ['01001234567']);
      expect(result.kind, WebContactPickKind.success);
      expect(result.isSuccess, isTrue);
      expect(result.phones, ['01001234567']);
    });

    test('cancelled / unsupported / failed have empty phones', () {
      expect(WebContactPickResult.cancelled().phones, isEmpty);
      expect(WebContactPickResult.unsupported().kind, WebContactPickKind.unsupported);
      expect(WebContactPickResult.failed().isSuccess, isFalse);
      expect(WebContactPickResult.noPhone().kind, WebContactPickKind.noPhone);
    });
  });

  group('VM / native stub', () {
    test('reports Contact Picker as unsupported', () {
      expect(isWebContactPickerSupported(), isFalse);
    });

    test('pick returns unsupported without throwing', () async {
      final result = await pickWebContactPhones();
      expect(result.kind, WebContactPickKind.unsupported);
      expect(result.phones, isEmpty);
    });
  });
}
