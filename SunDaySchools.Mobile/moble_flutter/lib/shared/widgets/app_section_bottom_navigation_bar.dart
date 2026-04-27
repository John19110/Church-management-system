import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/routing/app_router.dart';

class AppSectionBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final String homeRoute;

  const AppSectionBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.homeRoute,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        if (index == currentIndex) return;
        switch (index) {
          case 0:
            context.go(homeRoute);
            break;
          case 1:
            context.go(AppRoutes.notifications);
            break;
          case 2:
            context.go(AppRoutes.servants);
            break;
          case 3:
            context.go(AppRoutes.profile);
            break;
        }
      },
      destinations: [
        NavigationDestination(icon: const Icon(Icons.home_outlined), label: l10n.home),
        NavigationDestination(
          icon: const Icon(Icons.notifications_outlined),
          label: l10n.notifications,
        ),
        NavigationDestination(
          icon: const Icon(Icons.people_outline),
          label: l10n.servants,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          label: l10n.profile,
        ),
      ],
    );
  }
}
