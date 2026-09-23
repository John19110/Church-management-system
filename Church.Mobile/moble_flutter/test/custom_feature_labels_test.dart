import 'package:church_app/core/l10n/app_localizations.dart';
import 'package:church_app/features/custom_feature/models/custom_feature_models.dart';
import 'package:church_app/features/custom_feature/utils/custom_feature_labels.dart';
import 'package:church_app/features/custom_feature/widgets/dynamic_record_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const field = CustomEntityFieldReadDto(
    id: 1,
    entityId: 1,
    name: 'busNumber',
    displayName: 'Bus Number',
    displayNameAr: 'رقم الأتوبيس',
    fieldType: CustomEntityFieldType.text,
    isRequired: true,
    isUnique: false,
    isSearchable: true,
    showOnList: true,
    showOnForm: true,
    showOnDetails: true,
    displayOrder: 0,
  );

  const entity = CustomEntityReadDto(
    id: 1,
    featureId: 1,
    name: 'bus',
    displayName: 'Bus',
    displayNameAr: 'أتوبيس',
    pluralDisplayName: 'Buses',
    pluralDisplayNameAr: 'أتوبيسات',
    isActive: true,
    sortOrder: 0,
    fields: [field],
    permissions: [
      CustomEntityPermissionDto(
        roleName: 'Servant',
        canCreate: false,
        canRead: true,
        canUpdate: false,
        canDelete: false,
      ),
    ],
  );

  test('field and entity labels follow locale', () {
    final en = AppLocalizations(const Locale('en'));
    final ar = AppLocalizations(const Locale('ar'));

    expect(fieldDisplayName(field, en), 'Bus Number');
    expect(fieldDisplayName(field, ar), 'رقم الأتوبيس');
    expect(entityPluralName(entity, en), 'Buses');
    expect(entityPluralName(entity, ar), 'أتوبيسات');
    expect(entity.permissionForRole('servant')?.canRead, isTrue);
    expect(entity.permissionForRole('servant')?.canCreate, isFalse);
  });

  testWidgets('dynamic form shows required field in English and Arabic', (
    tester,
  ) async {
    Future<void> pump(Locale locale) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: Form(
              child: DynamicRecordFormFields(
                entity: entity,
                values: <String, dynamic>{},
                onChanged: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pump(const Locale('en'));
    expect(find.text('Bus Number'), findsOneWidget);

    await pump(const Locale('ar'));
    expect(find.text('رقم الأتوبيس'), findsOneWidget);
  });

  test('record title uses first list field', () {
    const record = CustomEntityRecordReadDto(
      id: 9,
      entityId: 1,
      values: {'busNumber': '01'},
    );
    final en = AppLocalizations(const Locale('en'));
    expect(recordTitle(record, entity, en), '01');
  });
}
