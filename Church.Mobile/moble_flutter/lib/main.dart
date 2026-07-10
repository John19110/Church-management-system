import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'core/l10n/app_localizations.dart';
import 'core/storage/token_storage.dart';
import 'core/cache/local_cache_service.dart';
import 'core/cache/tenant_cache_sync.dart';
import 'features/auth/providers/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await LocalCacheService.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Single secure-storage read before first frame; reused by router + Dio.
  await TokenStorage.warmCache();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ChurchApp(),
    ),
  );
}

class ChurchApp extends ConsumerStatefulWidget {
  const ChurchApp({super.key});

  @override
  ConsumerState<ChurchApp> createState() => _ChurchAppState();
}

class _ChurchAppState extends ConsumerState<ChurchApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (TokenStorage.cachedToken?.isNotEmpty == true) {
        ref.read(authStateProvider.notifier).state = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Keep tenant cache isolation enforced on church switches.
    ref.watch(tenantCacheSyncProvider);
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: AppLocalizations(locale).sundaySchool,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
