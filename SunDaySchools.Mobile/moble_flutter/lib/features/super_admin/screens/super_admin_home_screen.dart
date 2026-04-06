import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/token_storage.dart';
import '../../meetings/providers/meeting_providers.dart';
import '../../super_admin/providers/super_admin_providers.dart';

class SuperAdminHomeScreen extends ConsumerWidget {
  const SuperAdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingsAsync = ref.watch(visibleMeetingsProvider);
    final pendingAdminsAsync = ref.watch(pendingAdminsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Home'),
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
          ref.invalidate(visibleMeetingsProvider);
          ref.invalidate(pendingAdminsProvider);
          await ref.read(visibleMeetingsProvider.future);
          await ref.read(pendingAdminsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Pending Admins'),
                subtitle: pendingAdminsAsync.when(
                  data: (list) => Text('${list.length} pending'),
                  loading: () => const Text('Loading...'),
                  error: (e, _) => Text('Error: $e'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Visible Meetings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            meetingsAsync.when(
              data: (meetings) {
                if (meetings.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No visible meetings found.'),
                    ),
                  );
                }
                return Column(
                  children: meetings
                      .map(
                        (m) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.groups),
                            title: Text(m.name ?? '-'),
                            subtitle: Text(
                              'Servants: ${m.servantsCount} • Members: ${m.membersCount}',
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
                  child: Text('Failed to load visible meetings: $e'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
