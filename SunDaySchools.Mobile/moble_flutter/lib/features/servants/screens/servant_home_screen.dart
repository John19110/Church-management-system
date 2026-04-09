import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/storage/token_storage.dart';
import '../../classrooms/screens/classrooms_home_screen.dart';
import '../../auth/providers/auth_providers.dart';

class ServantHomeScreen extends ConsumerWidget {
  const ServantHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(currentUserRoleProvider);
    final role = roleAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servant'),
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
          : (role == 'servant'
              ? const ClassroomsHomeScreen()
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'This screen is for Servant users only.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )),
    );
  }
}

