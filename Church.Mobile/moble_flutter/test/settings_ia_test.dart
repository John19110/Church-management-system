import 'package:church_app/core/l10n/app_localizations.dart';
import 'package:church_app/core/providers/customization_language_provider.dart';
import 'package:church_app/core/providers/locale_provider.dart';
import 'package:church_app/core/providers/shared_preferences_provider.dart';
import 'package:church_app/core/providers/theme_provider.dart';
import 'package:church_app/features/custom_feature/models/custom_feature_models.dart';
import 'package:church_app/features/custom_feature/utils/custom_feature_labels.dart';
import 'package:church_app/features/settings/models/language_settings.dart';
import 'package:church_app/features/settings/providers/language_settings_providers.dart';
import 'package:church_app/features/auth/providers/auth_providers.dart';
import 'package:church_app/features/settings/screens/customization_hub_screen.dart';
import 'package:church_app/features/settings/screens/settings_screen.dart';
import 'package:church_app/features/settings/widgets/appearance_mode_card.dart';
import 'package:church_app/features/settings/widgets/application_language_card.dart';
import 'package:church_app/features/settings/widgets/customization_language_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('customization language stays independent of application locale', () async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        churchLanguagesProvider.overrideWith(
          (ref) async => ChurchLanguages.bilingual(),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(localeProvider).languageCode, 'ar');
    expect(container.read(customizationLanguageProvider), isEmpty);
    expect(container.read(resolvedCustomizationLanguageProvider), 'en');

    await container.read(customizationLanguageProvider.notifier).setLanguage('ar');

    expect(container.read(customizationLanguageProvider), 'ar');
    expect(container.read(resolvedCustomizationLanguageProvider), 'ar');
    expect(container.read(localeProvider).languageCode, 'ar');
    expect(prefs.getString(customizationLocalePrefsKey), 'ar');
    expect(prefs.getString('app_locale'), isNull);

    await container.read(localeProvider.notifier).setLocale(const Locale('en'));

    expect(container.read(localeProvider).languageCode, 'en');
    expect(container.read(customizationLanguageProvider), 'ar');
  });

  test('new IA strings are localized in English and Arabic', () {
    final en = AppLocalizations(const Locale('en'));
    final ar = AppLocalizations(const Locale('ar'));

    expect(en.applicationLanguage, 'Application Language');
    expect(ar.applicationLanguage, 'لغة التطبيق');
    expect(en.customizationLanguage, 'Customization Language');
    expect(ar.customizationLanguage, 'لغة التخصيص');
    expect(en.appearance, 'Appearance');
    expect(ar.appearance, 'المظهر');
    expect(en.appearanceLight, 'Light');
    expect(ar.appearanceDark, 'داكن');
    expect(en.accountSection, 'Account');
    expect(ar.accountSection, 'الحساب');
    expect(en.applicationLanguageDescription, isNot(ar.applicationLanguageDescription));
    expect(
      en.customizationLanguageDescription,
      isNot(ar.customizationLanguageDescription),
    );
  });

  test('custom feature labels honor an explicit working language', () {
    const feature = CustomFeatureReadDto(
      id: 1,
      name: 'buses',
      displayName: 'Buses',
      displayNameAr: 'الأتوبيسات',
      isActive: true,
    );
    final en = AppLocalizations(const Locale('en'));

    expect(featureDisplayName(feature, en), 'Buses');
    expect(
      featureDisplayName(feature, en, languageCode: 'ar'),
      'الأتوبيسات',
    );
  });

  testWidgets('language and appearance cards use distinct localized copy', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          churchLanguagesProvider.overrideWith(
            (ref) async => ChurchLanguages.bilingual(),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  ApplicationLanguageCard(),
                  CustomizationLanguageCard(),
                  AppearanceModeCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Application Language'), findsOneWidget);
    expect(
      find.text(
        'Choose the language used throughout the My Church application.',
      ),
      findsOneWidget,
    );
    expect(find.text('Customization Language'), findsOneWidget);
    expect(
      find.text(
        'Choose the language used when creating and managing custom fields and custom features. This does not change the language of the My Church application.',
      ),
      findsOneWidget,
    );
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Choose how My Church looks on your device.'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Delete Account'), findsNothing);
  });

  testWidgets('customization language does not change application locale', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'en'});
    final prefs = await SharedPreferences.getInstance();
    late ProviderContainer container;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          churchLanguagesProvider.overrideWith(
            (ref) async => ChurchLanguages.bilingual(),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return const MaterialApp(
              locale: Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(body: CustomizationLanguageCard()),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(localeProvider).languageCode, 'en');

    await tester.tap(find.text('Arabic'));
    await tester.pumpAndSettle();

    expect(container.read(customizationLanguageProvider), 'ar');
    expect(container.read(localeProvider).languageCode, 'en');
  });

  testWidgets('appearance card updates the existing theme provider', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    late ProviderContainer container;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return const MaterialApp(
              locale: Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(body: AppearanceModeCard()),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.light);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(prefs.getString(themePrefsKey), 'dark');

    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  testWidgets('settings keeps application language and a single delete account', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          churchLanguagesProvider.overrideWith(
            (ref) async => ChurchLanguages.bilingual(),
          ),
          currentUserRoleProvider.overrideWith((ref) async => 'admin'),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Application Language'), findsOneWidget);
    expect(find.text('Customization Language'), findsNothing);
    expect(find.text('Languages'), findsOneWidget);
    expect(find.text('Delete Account'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Danger zone'), findsOneWidget);
  });

  testWidgets('Arabic settings and customization copy is used in RTL', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          churchLanguagesProvider.overrideWith(
            (ref) async => ChurchLanguages.bilingual(),
          ),
          currentUserRoleProvider.overrideWith((ref) async => 'admin'),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('لغة التطبيق'), findsOneWidget);
    expect(find.text('حذف الحساب'), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('ar'),
    );
    expect(
      Directionality.of(tester.element(find.text('لغة التطبيق'))),
      TextDirection.rtl,
    );
  });

  testWidgets('customization shows working language and not app language', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          churchLanguagesProvider.overrideWith(
            (ref) async => ChurchLanguages.bilingual(),
          ),
          currentUserRoleProvider.overrideWith((ref) async => 'admin'),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: CustomizationHubScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Customization Language'), findsOneWidget);
    expect(find.byType(CustomizationLanguageCard), findsOneWidget);
    expect(find.text('Application Language'), findsNothing);
    expect(find.text('Languages'), findsNothing);
    expect(find.text('Appearance'), findsNothing);
    expect(find.text('Delete Account'), findsNothing);
    expect(find.text('Custom fields', skipOffstage: false), findsOneWidget);
    expect(find.text('Features', skipOffstage: false), findsOneWidget);
  });
}
