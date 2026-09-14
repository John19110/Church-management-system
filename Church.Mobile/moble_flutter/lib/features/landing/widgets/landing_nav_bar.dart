import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import 'landing_section.dart';

class LandingNavBar extends ConsumerWidget {
  const LandingNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final isArabic = locale.languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    // Arabic Login/Register labels are much wider than English; switch to icon
    // actions earlier so language + theme toggles are never clipped by Row overflow.
    final compact = width < (isArabic ? 920 : 720);

    return Material(
      color: scheme.surface.withValues(alpha: 0.92),
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                // Brand may shrink; action controls keep intrinsic size and stay visible.
                child: Row(
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/app_logo_adjusted.png',
                            height: 36,
                            width: 36,
                            fit: BoxFit.contain,
                            semanticLabel: l10n.appTitle,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              l10n.appTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : AppColors.navy,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: isArabic ? l10n.english : l10n.arabic,
                      child: Tooltip(
                        message: isArabic ? l10n.english : l10n.arabic,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () =>
                              ref.read(localeProvider.notifier).toggle(),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundImage: AssetImage(
                                isArabic
                                    ? 'assets/flags/uk.png'
                                    : 'assets/flags/eg.png',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: isDark ? l10n.lightMode : l10n.darkMode,
                      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                      onPressed: () =>
                          ref.read(themeModeProvider.notifier).toggle(),
                    ),
                    if (!compact) ...[
                      TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: Text(l10n.login),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      FilledButton(
                        onPressed: () => context.go(AppRoutes.register),
                        child: Text(l10n.register),
                      ),
                    ] else ...[
                      IconButton(
                        tooltip: l10n.login,
                        onPressed: () => context.go(AppRoutes.login),
                        icon: const Icon(Icons.login),
                      ),
                      IconButton(
                        tooltip: l10n.register,
                        onPressed: () => context.go(AppRoutes.register),
                        icon: const Icon(Icons.person_add_alt_1),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
