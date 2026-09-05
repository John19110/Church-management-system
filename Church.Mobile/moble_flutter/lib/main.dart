import 'dart:async';

import 'package:flutter/foundation.dart';
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
import 'core/notifications/notification_navigation_listener.dart';
import 'core/notifications/notification_service.dart';
import 'core/startup/app_launch_splash.dart';
import 'core/startup/splash_theme_sync.dart';
import 'features/auth/providers/auth_providers.dart';
import 'shared/widgets/app_form_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Need prefs before first splash paint so light/dark matches app ThemeMode.
    final prefs = await SharedPreferences.getInstance();
    final themeMode = ThemeController.loadInitial(prefs);
    // Keep native splash in sync for this process + next cold start.
    unawaited(SplashThemeSync.sync(themeMode));
    // Must await: post-frame session restore reads TokenStorage.cachedToken.
    // If warmCache is still in flight, cachedToken is null and FCM setup is skipped.
    await TokenStorage.warmCache();

    // Firebase + FCM must initialize before runApp (background handler registration).
    await NotificationService.bootstrap();

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const ChurchApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('STARTUP ERROR: $e');
    debugPrintStack(stackTrace: stackTrace);
    runApp(_StartupErrorApp(error: e));
  }
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

      // First launch: prompt once after Firebase bootstrap when the UI is ready.
      unawaited(NotificationService.requestLaunchNotificationPermission());
      // warmCache is awaited in main; still fall back to async read if needed.
      unawaited(_restoreSessionAndNotifications());
      unawaited(_finishLaunchSplash());
    });
  }

  Future<void> _restoreSessionAndNotifications() async {
    final token = TokenStorage.cachedToken ?? await TokenStorage.getToken();
    final hasSession = token != null && token.isNotEmpty;
    if (kDebugMode) {
      debugPrint(
        '[FCM] session restore check: cacheWarm=${TokenStorage.isCacheWarm} '
        'hasSession=$hasSession',
      );
    }
    if (!hasSession) return;
    if (!mounted) return;
    ref.read(authStateProvider.notifier).state = true;
    await NotificationService.instance.onUserAuthenticated();
  }

  Future<void> _finishLaunchSplash() async {
    try {
      final context = this.context;
      await Future.wait<void>([
        LocalCacheService.ensureInitialized(),
        precacheImage(const AssetImage(AppLaunchSplash.logoAsset), context),
      ]);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[Splash] Launch prep failed: $e');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

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
            Positioned.fill(
              child: MaterialApp.router(
              title: AppLocalizations(locale).appTitle,
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
                  child: NotificationNavigationListener(
                    child: AppKeyboardDismiss(
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                );
              },
            ),
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

/// Shown when [main] fails before the real app can mount (avoids a blank page).
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SelectableText(
                'Startup error:\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
