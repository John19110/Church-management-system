import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../../../shared/widgets/app_section_bottom_navigation_bar.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final homeRoute = AuthRoleUtils.routeForRole(role);
    final currentLocation = GoRouterState.of(context).matchedLocation;

    return PopScope(
      canPop: currentLocation == homeRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go(homeRoute);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.notifications)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.noNotificationsYet),
          ),
        ),
        bottomNavigationBar: AppSectionBottomNavigationBar(
          currentIndex: 1,
          homeRoute: homeRoute,
        ),
      ),
    );
  }
}

