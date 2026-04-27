import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_session.dart';
import 'profile_screen.dart';

class ServantHomeScreen extends ConsumerWidget {
  const ServantHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final roleAsync = ref.watch(currentUserRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.servant),
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
                l10n.servantOnlyScreen,
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
    );
  }
}

