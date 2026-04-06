import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/token_storage.dart';
import '../../admin/providers/admin_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/classroom_providers.dart';

class ClassroomsHomeScreen extends ConsumerWidget {
  const ClassroomsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(currentUserRoleProvider);
    final classroomsAsync = ref.watch(visibleClassroomsProvider);
    final role = roleAsync.valueOrNull;
    final canViewPendingServants = role == 'admin';
    final pendingServantsAsync =
        canViewPendingServants ? ref.watch(pendingServantsProvider) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classrooms Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await TokenStorage.deleteToken();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(visibleClassroomsProvider);
          await ref.read(visibleClassroomsProvider.future);
          if (canViewPendingServants) {
            ref.invalidate(pendingServantsProvider);
            try {
              await ref.read(pendingServantsProvider.future);
            } catch (_) {}
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.pending_actions),
                title: const Text('Pending Servants'),
                subtitle: !canViewPendingServants
                    ? const Text('Available for Admin only')
                    : pendingServantsAsync!.when(
                        data: (list) => Text('${list.length} pending'),
                        loading: () => const Text('Loading...'),
                        error: (e, _) => Text('Failed: $e'),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Visible Classrooms',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            classroomsAsync.when(
              data: (classrooms) {
                if (classrooms.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No visible classrooms found.'),
                    ),
                  );
                }
                return Column(
                  children: classrooms
                      .map(
                        (c) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.class_),
                            title: Text(c.name ?? '-'),
                            subtitle: Text(
                              'Age: ${c.ageOfMembers ?? '-'} • Members: ${c.totalMembersCount ?? 0}',
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Failed to load visible classrooms: $e'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
