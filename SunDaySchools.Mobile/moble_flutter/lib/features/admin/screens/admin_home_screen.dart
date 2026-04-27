import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_session.dart';
import '../../classroom/screens/classrooms_home_screen.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final roleAsync = ref.watch(currentUserRoleProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.admin),
          bottom: TabBar(
            tabs: [
              Tab(icon: const Icon(Icons.class_), text: l10n.classrooms),
              Tab(
                icon: const Icon(Icons.pending_actions),
                text: l10n.pendingServants,
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => logoutSession(ref, context),
            ),
          ],
        ),
        body: roleAsync.when(
          data: (role) {
            if (role == 'admin') {
              return const TabBarView(
                children: [
                  ClassroomsHomeScreen(showAppBar: false),
                  _PendingServantsRouteShim(),
                ],
              );
            }
            if (role == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.noRoleFoundPleaseRelogin,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.adminOnlyScreen,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${l10n.couldNotVerifyRole} $e',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingServantsRouteShim extends StatelessWidget {
  const _PendingServantsRouteShim();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Uses a dedicated route/screen so it can also be opened directly.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () => context.go(AppRoutes.pendingServants),
          icon: const Icon(Icons.open_in_new),
          label: Text(l10n.openPendingServants),
        ),
      ),
    );
  }
}

