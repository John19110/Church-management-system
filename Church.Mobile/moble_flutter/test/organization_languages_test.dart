import 'package:church_app/core/l10n/organization_languages.dart';
import 'package:church_app/features/servant/models/pending_request.dart';
import 'package:church_app/features/super_admin/models/super_admin_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fallback uses default language when preferred translation is empty', () {
    expect(
      OrganizationLanguages.pickTranslation(
        userLanguage: 'ar',
        defaultLanguage: 'en',
        english: 'Birth Date',
        arabic: '',
      ),
      'Birth Date',
    );
  });

  test('merge pending requests keeps one row per user', () {
    final merged = mergePendingRequests(
      registrations: [
        PendingChurchUserDto(
          id: '1',
          name: 'John',
          phoneNumber: '1',
          role: 'Servant',
          requestedRole: 'Servant',
        ),
      ],
      legacyServants: [
        const PendingUserDto(id: '1', name: 'John', phoneNumber: '1'),
        const PendingUserDto(id: '2', name: 'Mina', phoneNumber: '2'),
      ],
    );
    expect(merged.map((r) => r.id), ['1', '2']);
    expect(merged.first.source, PendingRequestSource.registration);
  });
}
