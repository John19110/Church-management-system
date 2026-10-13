import 'package:church_app/core/l10n/app_localizations.dart';
import 'package:church_app/core/providers/shared_preferences_provider.dart';
import 'package:church_app/features/settings/models/language_settings.dart';
import 'package:church_app/features/settings/providers/language_settings_providers.dart';
import 'package:church_app/features/settings/widgets/translated_name_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap({
  required Locale locale,
  required ChurchLanguages church,
  required TextEditingController english,
  required TextEditingController arabic,
}) {
  return ProviderScope(
    overrides: [churchLanguagesProvider.overrideWith((ref) async => church)],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: TranslatedNameFields(english: english, arabic: arabic),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Arabic app + unconfigured church shows single Arabic Name field',
    (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'ar'});
      final prefs = await SharedPreferences.getInstance();
      final english = TextEditingController();
      final arabic = TextEditingController();
      addTearDown(english.dispose);
      addTearDown(arabic.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            churchLanguagesProvider.overrideWith(
              (ref) async => ChurchLanguages.bilingual(isConfigured: false),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: TranslatedNameFields(english: english, arabic: arabic),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الاسم *'), findsOneWidget);
      expect(find.textContaining('الإنجليزية'), findsNothing);
      expect(find.textContaining('English'), findsNothing);
    },
  );

  testWidgets('Arabic app + configured bilingual shows Arabic then English', (
    tester,
  ) async {
    final english = TextEditingController();
    final arabic = TextEditingController();
    addTearDown(english.dispose);
    addTearDown(arabic.dispose);

    await tester.pumpWidget(
      _wrap(
        locale: const Locale('ar'),
        church: ChurchLanguages.bilingual(isConfigured: true),
        english: english,
        arabic: arabic,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الاسم بالعربية *'), findsOneWidget);
    expect(find.text('الاسم بالإنجليزية *'), findsOneWidget);

    final arabicOffset = tester.getTopLeft(find.text('الاسم بالعربية *'));
    final englishOffset = tester.getTopLeft(find.text('الاسم بالإنجليزية *'));
    expect(arabicOffset.dy < englishOffset.dy, isTrue);
  });

  testWidgets('English app + configured bilingual shows English then Arabic', (
    tester,
  ) async {
    final english = TextEditingController();
    final arabic = TextEditingController();
    addTearDown(english.dispose);
    addTearDown(arabic.dispose);

    await tester.pumpWidget(
      _wrap(
        locale: const Locale('en'),
        church: ChurchLanguages.bilingual(isConfigured: true),
        english: english,
        arabic: arabic,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('English name *'), findsOneWidget);
    expect(find.text('Arabic name *'), findsOneWidget);

    final englishOffset = tester.getTopLeft(find.text('English name *'));
    final arabicOffset = tester.getTopLeft(find.text('Arabic name *'));
    expect(englishOffset.dy < arabicOffset.dy, isTrue);
  });
}
