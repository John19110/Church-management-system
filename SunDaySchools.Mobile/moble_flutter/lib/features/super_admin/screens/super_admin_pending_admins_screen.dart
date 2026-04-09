import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/common_widgets.dart' as cw;
import '../providers/super_admin_providers.dart';

class SuperAdminPendingAdminsScreen extends ConsumerWidget {
  const SuperAdminPendingAdminsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingAdminsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Admins')),
      body: pendingAsync.when(
        loading: () => const cw.LoadingWidget(),
        error: (e, _) => cw.AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(pendingAdminsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const cw.EmptyWidget(
              message: 'No pending admins.',
              icon: Icons.admin_panel_settings,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(pendingAdminsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final u = list[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined),
                    title: Text(u.name.isEmpty ? '(no name)' : u.name),
                    subtitle:
                        Text(u.phoneNumber.isEmpty ? '(no phone)' : u.phoneNumber),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          tooltip: 'Approve',
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () async {
                            try {
                              await ref
                                  .read(superAdminRepositoryProvider)
                                  .approveAdmin(u.id);
                              ref.invalidate(pendingAdminsProvider);
                              if (context.mounted) {
                                cw.showSuccessSnackbar(
                                  context,
                                  'Approved ${u.name}.',
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                cw.showErrorSnackbar(context, e.toString());
                              }
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Reject',
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () async {
                            final ok = await cw.showConfirmDialog(
                              context,
                              title: 'Reject admin?',
                              content:
                                  'This will reject ${u.name.isEmpty ? 'this user' : u.name}.',
                              confirmText: 'Reject',
                            );
                            if (!ok) return;
                            try {
                              await ref
                                  .read(superAdminRepositoryProvider)
                                  .rejectAdmin(u.id);
                              ref.invalidate(pendingAdminsProvider);
                              if (context.mounted) {
                                cw.showSuccessSnackbar(
                                  context,
                                  'Rejected ${u.name}.',
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                cw.showErrorSnackbar(context, e.toString());
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

