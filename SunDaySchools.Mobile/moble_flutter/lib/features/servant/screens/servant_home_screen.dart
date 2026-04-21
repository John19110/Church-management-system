import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_session.dart';
import 'profile_screen.dart';

class ServantHomeScreen extends ConsumerWidget {
  const ServantHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(currentUserRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logoutSession(ref, context),
          ),
        ],
      ),
      body: roleAsync.when(
        data: (role) {
          if (role == 'servant') {
            return const ProfileScreen(showAppBar: false);
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
                'This screen is for Servant users only.',
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
    );
  }
}

