import 'package:church_app/core/l10n/app_localizations.dart';
import 'package:church_app/core/providers/locale_provider.dart';
import 'package:church_app/core/providers/shared_preferences_provider.dart';
import 'package:church_app/core/providers/theme_provider.dart';
import 'package:church_app/features/auth/providers/auth_providers.dart';
import 'package:church_app/features/settings/models/language_settings.dart';
import 'package:church_app/features/settings/providers/language_settings_providers.dart';
import 'package:church_app/features/settings/screens/customization_hub_screen.dart';
import 'package:church_app/features/settings/widgets/appearance_mode_card.dart';
import 'package:church_app/features/settings/widgets/customization_languages_section.dart';
import 'package:church_app/features/servant/widgets/application_language_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'app_locale': 'en'});
  });

  test('new IA strings are localized in English and Arabic', () {
    final en = AppLocalizations(const Locale('en'));
    final ar = AppLocalizations(const Locale('ar'));

    expect(en.applicationLanguage, 'Application Language');
    expect(ar.applicationLanguage, 'لغة التطبيق');
    expect(en.customizationLanguagesTitle, 'Customization Languages');
    expect(ar.customizationLanguagesTitle, 'لغات التخصيص');
    expect(
      en.customizationLanguagesOtherQuestion('Arabic'),
      'Is Arabic used by anyone in this meeting/church?',
    );
    expect(
      ar.customizationLanguagesOtherQuestion('الإنجليزية'),
      contains('الإنجليزية'),
    );
  });

  testWidgets('application language card is on profile widgets', (tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          churchLanguagesProvider.overrideWith(
            (ref) async => ChurchLanguages.bilingual(isConfigured: true),
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
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Customization Languages'), findsNothing);
  });

  testWidgets('first-time customization shows setup and not field hubs', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          churchLanguagesProvider.overrideWith(
            (ref) async => const ChurchLanguages(
              supportedLanguages: ['en'],
              defaultLanguage: 'en',
              isConfigured: false,
            ),
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

    expect(find.byType(CustomizationLanguagesSection), findsOneWidget);
    expect(find.text('Customization Languages'), findsOneWidget);
    expect(
      find.text('Is Arabic used by anyone in this meeting/church?'),
      findsOneWidget,
    );
    expect(find.text('Custom fields', skipOffstage: false), findsNothing);
    expect(find.text('Features', skipOffstage: false), findsNothing);
    expect(find.text('Application Language'), findsNothing);
  });

  testWidgets('configured customization shows summary and edit', (tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          churchLanguagesProvider.overrideWith(
            (ref) async => ChurchLanguages.bilingual(isConfigured: true),
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

    expect(find.text('English + Arabic'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(
      find.text('Is Arabic used by anyone in this meeting/church?'),
      findsNothing,
    );
    expect(find.text('Custom fields', skipOffstage: false), findsOneWidget);
    expect(find.text('Features', skipOffstage: false), findsOneWidget);
  });

  testWidgets('arabic app language asks about English in setup', (tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ar'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          churchLanguagesProvider.overrideWith(
            (ref) async => const ChurchLanguages(
              supportedLanguages: ['ar'],
              defaultLanguage: 'ar',
              isConfigured: false,
            ),
          ),
          currentUserRoleProvider.overrideWith((ref) async => 'admin'),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: CustomizationHubScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('الإنجليزية'), findsWidgets);
    expect(
      Directionality.of(tester.element(find.text('لغات التخصيص'))),
      TextDirection.rtl,
    );
  });

  testWidgets('appearance card updates theme provider', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    late ProviderContainer container;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
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

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  testWidgets('application language changes locale without church constraint', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    late ProviderContainer container;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          churchLanguagesProvider.overrideWith(
            (ref) async => const ChurchLanguages(
              supportedLanguages: ['ar'],
              defaultLanguage: 'ar',
              isConfigured: true,
            ),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return MaterialApp(
              locale: ref.watch(localeProvider),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: const Scaffold(body: ApplicationLanguageCard()),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Arabic'));
    await tester.pumpAndSettle();
    expect(container.read(localeProvider).languageCode, 'ar');
  });
}
