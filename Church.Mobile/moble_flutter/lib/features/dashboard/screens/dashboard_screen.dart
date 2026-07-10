import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/utils/auth_session.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/app_stat_card.dart';
import '../../../shared/widgets/section_header.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final isArabic = locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
        actions: [
          // Language toggle
          TextButton(
            onPressed: () => ref.read(localeProvider.notifier).toggle(),
            child: Text(
              isArabic ? 'EN' : 'ع',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          // Dark mode toggle
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDark ? l10n.lightMode : l10n.darkMode,
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.logout,
            onPressed: () => logoutSession(ref, context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WelcomeBanner(
                title: l10n.welcome,
                subtitle: l10n.sundaySchoolManagement,
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(title: l10n.quickAccess),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 640 ? 3 : 2;
                  final palette = context.palette;
                  final scheme = Theme.of(context).colorScheme;
                  final items = <_DashboardAction>[
                    _DashboardAction(
                      icon: Icons.child_care,
                      label: l10n.members,
                      color: scheme.primary,
                      onTap: () => context.go(AppRoutes.member),
                    ),
                    _DashboardAction(
                      icon: Icons.class_,
                      label: l10n.classrooms,
                      color: palette.success,
                      onTap: () => context.go(AppRoutes.classroomsHome),
                    ),
                    _DashboardAction(
                      icon: Icons.people,
                      label: l10n.servants,
                      color: palette.warning,
                      onTap: () => context.go('/servants'),
                    ),
                    _DashboardAction(
                      icon: Icons.church,
                      label: l10n.churchName,
                      color: palette.navy,
                      onTap: () => context.push(AppRoutes.churchSettings),
                    ),
                    _DashboardAction(
                      icon: Icons.logout,
                      label: l10n.logout,
                      color: palette.danger,
                      onTap: () => logoutSession(ref, context),
                    ),
                  ];
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.05,
                    children: [
                      for (final item in items)
                        AppQuickAction(
                          icon: item.icon,
                          label: item.label,
                          color: item.color,
                          onTap: item.onTap,
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DashboardAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

/// Gradient welcome hero used at the top of the dashboard.
class _WelcomeBanner extends StatelessWidget {
  final String title;
  final String subtitle;

  const _WelcomeBanner({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.heroGradient,
        ),
        borderRadius: AppRadius.xlAll,
      ),
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: AppRadius.lgAll,
            ),
            child: const Icon(Icons.church, size: 30, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
