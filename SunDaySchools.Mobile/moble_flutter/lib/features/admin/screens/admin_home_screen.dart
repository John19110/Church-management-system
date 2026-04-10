import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/storage/token_storage.dart';
import '../../classroom/screens/classrooms_home_screen.dart';
import '../../auth/providers/auth_providers.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(currentUserRoleProvider);
    final role = roleAsync.valueOrNull;

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
              onPressed: () async {
                await TokenStorage.deleteToken();
                if (context.mounted) context.go(AppRoutes.login);
              },
            ),
          ],
        ),
        body: roleAsync.isLoading
            ? const Center(child: CircularProgressIndicator())
            : (role == 'admin'
                ? const TabBarView(
                    children: [
                      ClassroomsHomeScreen(),
                      _PendingServantsRouteShim(),
                    ],
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'This screen is for Admin users only.',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )),
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

