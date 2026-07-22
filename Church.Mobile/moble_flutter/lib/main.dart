import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'core/startup/app_launch_splash.dart';
import 'core/startup/splash_theme_sync.dart';
import 'features/auth/providers/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Need prefs before first splash paint so light/dark matches app ThemeMode.
  final prefs = await SharedPreferences.getInstance();
  final themeMode = ThemeController.loadInitial(prefs);
  // Keep native splash in sync for this process + next cold start.
  unawaited(SplashThemeSync.sync(themeMode));
  unawaited(TokenStorage.warmCache());

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

class _ChurchAppState extends ConsumerState<ChurchApp>
    with SingleTickerProviderStateMixin {
  bool _showSplashOverlay = true;
  double _splashOpacity = 1;
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(() {
        setState(() => _splashOpacity = 1 - _fadeController.value);
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (TokenStorage.cachedToken?.isNotEmpty == true) {
        ref.read(authStateProvider.notifier).state = true;
      }

      unawaited(_finishLaunchSplash());
    });
  }

  Future<void> _finishLaunchSplash() async {
    final context = this.context;
    await Future.wait<void>([
      LocalCacheService.ensureInitialized(),
      precacheImage(const AssetImage(AppLaunchSplash.logoAsset), context),
    ]);

    if (!mounted) return;
    await _fadeController.forward();
    if (!mounted) return;
    setState(() => _showSplashOverlay = false);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(tenantCacheSyncProvider);
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final splashIsDark = resolveSplashIsDark(themeMode, platformBrightness);

    return MediaQuery(
      data: MediaQueryData.fromView(
        WidgetsBinding.instance.platformDispatcher.views.first,
      ),
      child: Directionality(
        textDirection: locale.languageCode == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            MaterialApp.router(
              title: AppLocalizations(locale).sundaySchool,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              routerConfig: router,
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                final bg = Theme.of(context).scaffoldBackgroundColor;
                return ColoredBox(
                  color: bg,
                  child: child ?? const SizedBox.shrink(),
                );
              },
            ),
            if (_showSplashOverlay)
              Positioned.fill(
                child: IgnorePointer(
                  child: AppLaunchSplash(
                    isDark: splashIsDark,
                    opacity: _splashOpacity,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
