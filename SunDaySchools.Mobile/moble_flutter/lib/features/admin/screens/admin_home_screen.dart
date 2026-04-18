import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_session.dart';
import '../../classroom/screens/classrooms_home_screen.dart';
import '../../../shared/widgets/app_section_bottom_navigation_bar.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(currentUserRoleProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.class_), text: 'Classrooms'),
              Tab(icon: Icon(Icons.pending_actions), text: 'Pending Servants'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => logoutSession(ref, context),
            ),
          ],
        ),
        bottomNavigationBar: const AppSectionBottomNavigationBar(
          currentIndex: 0,
          homeRoute: AppRoutes.adminHome,
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
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No role found in your session. Please log out and sign in again.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'This screen is for Admin users only.',
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
                'Could not verify your role: $e',
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
    // Uses a dedicated route/screen so it can also be opened directly.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () => context.go(AppRoutes.pendingServants),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Open Pending Servants'),
        ),
      ),
    );
  }
}

