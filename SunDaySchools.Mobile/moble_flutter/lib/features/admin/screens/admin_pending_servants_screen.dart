import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../classroom/providers/classroom_providers.dart';
import '../providers/admin_providers.dart';

class AdminPendingServantsScreen extends ConsumerWidget {
  const AdminPendingServantsScreen({super.key});

  Future<void> _assignClassDialog(
    BuildContext context,
    WidgetRef ref, {
    required int servantId,
  }) async {
    final classrooms = await ref.read(visibleClassroomsProvider.future);
    int? selectedClassroomId;

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Assign classroom'),
              content: DropdownButtonFormField<int>(
                initialValue: selectedClassroomId,
                items: classrooms
                    .where((c) => c.id != null)
                    .map(
                      (c) => DropdownMenuItem<int>(
                        value: c.id!,
                        child: Text('${c.name ?? 'Classroom'} (#${c.id})'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedClassroomId = v),
                decoration: const InputDecoration(
                  labelText: 'Classroom',
                  hintText: 'Select classroom',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedClassroomId == null) {
                      cw.showErrorSnackbar(ctx, 'Please select a classroom.');
                      return;
                    }
                    try {
                      await ref.read(adminRepositoryProvider).assignClass(
                            servantId,
                            selectedClassroomId!,
                          );
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (context.mounted) {
                        cw.showSuccessSnackbar(context, 'Class assigned.');
                      }
                    } catch (e) {
                      if (ctx.mounted) cw.showErrorSnackbar(ctx, e.toString());
                    }
                  },
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingServantsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Servants')),
      body: pendingAsync.when(
        loading: () => const cw.LoadingWidget(),
        error: (e, _) => cw.AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(pendingServantsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const cw.EmptyWidget(
              message: 'No pending servants.',
              icon: Icons.pending_actions,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(pendingServantsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final u = list[index];
                final servantId = int.tryParse(u.id);
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(u.name.isEmpty ? '(no name)' : u.name),
                    subtitle:
                        Text(u.phoneNumber.isEmpty ? '(no phone)' : u.phoneNumber),
                    isThreeLine: true,
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          tooltip: 'Approve',
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () async {
                            try {
                              await ref
                                  .read(adminRepositoryProvider)
                                  .approveServant(u.id);
                              ref.invalidate(pendingServantsProvider);
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
                              title: 'Reject servant?',
                              content:
                                  'This will reject ${u.name.isEmpty ? 'this user' : u.name}.',
                              confirmText: 'Reject',
                            );
                            if (!ok) return;
                            try {
                              await ref
                                  .read(adminRepositoryProvider)
                                  .rejectServant(u.id);
                              ref.invalidate(pendingServantsProvider);
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
                        IconButton(
                          tooltip: 'Assign class',
                          icon: const Icon(Icons.class_),
                          onPressed: servantId == null
                              ? null
                              : () => _assignClassDialog(
                                    context,
                                    ref,
                                    servantId: servantId,
                                  ),
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

