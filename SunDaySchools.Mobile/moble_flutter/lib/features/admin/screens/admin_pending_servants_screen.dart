import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../providers/admin_providers.dart';
import '../../../shared/widgets/endpoint_select_fields.dart';

class AdminPendingServantsScreen extends ConsumerWidget {
  const AdminPendingServantsScreen({super.key});

  Future<void> _assignClassDialog(
    BuildContext context,
    WidgetRef ref, {
    required int servantId,
  }) async {
    final l10n = AppLocalizations.of(context);
    int? selectedClassroomId;

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(l10n.assignClassroom),
              content: EndpointSelectDropdown(
                endpoint: SelectionEndpoints.classrooms,
                label: l10n.classroom,
                hintText: l10n.selectClassroom,
                value: selectedClassroomId,
                onChanged: (v) => setState(() => selectedClassroomId = v),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedClassroomId == null) {
                      cw.showErrorSnackbar(ctx, l10n.pleaseSelectClassroom);
                      return;
                    }
                    try {
                      await ref.read(adminRepositoryProvider).assignClass(
                            servantId,
                            selectedClassroomId!,
                          );
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (context.mounted) {
                        cw.showSuccessSnackbar(context, l10n.classAssigned);
                      }
                    } catch (e) {
                      if (ctx.mounted) cw.showErrorSnackbar(ctx, e.toString());
                    }
                  },
                  child: Text(l10n.assign),
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
    final l10n = AppLocalizations.of(context);
    final pendingAsync = ref.watch(pendingServantsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pendingServants)),
      body: pendingAsync.when(
        loading: () => const cw.LoadingWidget(),
        error: (e, _) => cw.AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(pendingServantsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return cw.EmptyWidget(
              message: l10n.noPendingServants,
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
                    title: Text(u.name.isEmpty ? l10n.noName : u.name),
                    subtitle: Text(
                      u.phoneNumber.isEmpty ? l10n.noPhone : u.phoneNumber,
                    ),
                    isThreeLine: true,
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          tooltip: l10n.approve,
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
                                  '${l10n.approvedUser} ${u.name}.',
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
                          tooltip: l10n.reject,
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () async {
                            final ok = await cw.showConfirmDialog(
                              context,
                              title: l10n.rejectServantTitle,
                              content:
                                  'This will reject ${u.name.isEmpty ? l10n.rejectThisUser : u.name}.',
                              confirmText: l10n.reject,
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
                                  '${l10n.rejectedUser} ${u.name}.',
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
                          tooltip: l10n.assignClassTooltip,
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

