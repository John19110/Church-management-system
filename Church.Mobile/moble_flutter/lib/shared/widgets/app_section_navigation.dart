import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../features/auth/utils/auth_role_utils.dart';
import 'app_content.dart';

/// Primary app sections shown in the bottom bar / navigation rail.
enum AppNavDestination { home, notifications, servants, approvals, profile }

List<AppNavDestination> appNavDestinationsForRole(String? role) {
  if (role == 'admin' || role == 'superadmin') {
    return const [
      AppNavDestination.home,
      AppNavDestination.notifications,
      AppNavDestination.servants,
      AppNavDestination.approvals,
      AppNavDestination.profile,
    ];
  }
  return const [
    AppNavDestination.home,
    AppNavDestination.notifications,
    AppNavDestination.servants,
    AppNavDestination.profile,
  ];
}

String appNavRouteFor(AppNavDestination destination, String homeRoute) {
  return switch (destination) {
    AppNavDestination.home => homeRoute,
    AppNavDestination.notifications => AppRoutes.notifications,
    AppNavDestination.servants => AppRoutes.servants,
    AppNavDestination.approvals => AppRoutes.approvals,
    AppNavDestination.profile => AppRoutes.profile,
  };
}

String appNavLabel(AppLocalizations l10n, AppNavDestination destination) {
  return switch (destination) {
    AppNavDestination.home => l10n.home,
    AppNavDestination.notifications => l10n.notifications,
    AppNavDestination.servants => l10n.servants,
    AppNavDestination.approvals => l10n.approvals,
    AppNavDestination.profile => l10n.profile,
  };
}

(IconData icon, IconData selected) appNavIcons(AppNavDestination destination) {
  return switch (destination) {
    AppNavDestination.home => (AppIcons.home, AppIcons.homeSelected),
    AppNavDestination.notifications => (
        AppIcons.notifications,
        AppIcons.notificationsSelected,
      ),
    AppNavDestination.servants => (AppIcons.servants, AppIcons.servantsSelected),
    AppNavDestination.approvals => (
        AppIcons.approvals,
        AppIcons.approvalsSelected,
      ),
    AppNavDestination.profile => (AppIcons.profile, AppIcons.profileSelected),
  };
}

void goAppNavDestination(
  BuildContext context, {
  required AppNavDestination destination,
  required String homeRoute,
}) {
  context.go(appNavRouteFor(destination, homeRoute));
}

/// Compact [NavigationBar] for phones.
class AppSectionBottomNavigationBar extends StatelessWidget {
  final AppNavDestination destination;
  final String homeRoute;
  final String? role;

  const AppSectionBottomNavigationBar({
    super.key,
    required this.destination,
    required this.homeRoute,
    this.role,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = appNavDestinationsForRole(role);
    final selectedIndex = items.indexOf(destination);
    return NavigationBar(
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onDestinationSelected: (index) {
        final next = items[index];
        if (next == destination) return;
        goAppNavDestination(
          context,
          destination: next,
          homeRoute: homeRoute,
        );
      },
      destinations: [
        for (final item in items)
          NavigationDestination(
            icon: Icon(appNavIcons(item).$1),
            selectedIcon: Icon(appNavIcons(item).$2),
            label: appNavLabel(l10n, item),
          ),
      ],
    );
  }
}

/// Side navigation for tablet and desktop.
class AppSectionNavigationRail extends StatelessWidget {
  final AppNavDestination destination;
  final String homeRoute;
  final String? role;
  final bool extended;

  const AppSectionNavigationRail({
    super.key,
    required this.destination,
    required this.homeRoute,
    this.role,
    this.extended = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = appNavDestinationsForRole(role);
    final selectedIndex = items.indexOf(destination);
    final palette = context.palette;

    return NavigationRail(
      extended: extended,
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      backgroundColor: Theme.of(context).colorScheme.surface,
      indicatorColor:
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
      selectedIconTheme: IconThemeData(
        color: Theme.of(context).colorScheme.primary,
      ),
      unselectedIconTheme: IconThemeData(color: palette.textTertiary),
      onDestinationSelected: (index) {
        final next = items[index];
        if (next == destination) return;
        goAppNavDestination(
          context,
          destination: next,
          homeRoute: homeRoute,
        );
      },
      destinations: [
        for (final item in items)
          NavigationRailDestination(
            icon: Icon(appNavIcons(item).$1),
            selectedIcon: Icon(appNavIcons(item).$2),
            label: Text(appNavLabel(l10n, item)),
          ),
      ],
    );
  }
}

class AppAdaptiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final AppNavDestination? destination;
  final String homeRoute;
  final String? role;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomAction;
  final bool constrainBody;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;

  const AppAdaptiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.destination,
    required this.homeRoute,
    this.role,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomAction,
    this.constrainBody = true,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final useRail = destination != null && context.useRailNavigation;
    final content = constrainBody ? AppContent(child: body) : body;

    Widget? compactBottom;
    if (destination != null && !useRail) {
      compactBottom = bottomAction == null
          ? AppSectionBottomNavigationBar(
              destination: destination!,
              homeRoute: homeRoute,
              role: role,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                bottomAction!,
                AppSectionBottomNavigationBar(
                  destination: destination!,
                  homeRoute: homeRoute,
                  role: role,
                ),
              ],
            );
    } else if (bottomAction != null && !useRail) {
      compactBottom = bottomAction;
    }

    final inner = Scaffold(
      appBar: appBar,
      body: content,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: useRail ? bottomAction : compactBottom,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );

    if (!useRail) return inner;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          AppSectionNavigationRail(
            destination: destination!,
            homeRoute: homeRoute,
            role: role,
            extended: context.useExtendedRail,
          ),
          VerticalDivider(
            width: 1,
            color: context.palette.border,
          ),
          Expanded(child: inner),
        ],
      ),
    );
  }
}

/// Convenience when only the role home route is needed.
String roleHomeRoute(String? role) => AuthRoleUtils.routeForRole(role);
