import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;
import '../../../core/routing/app_router.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../admin/models/admin_models.dart';
import '../../admin/providers/admin_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../models/classroom_models.dart';
import '../providers/classroom_providers.dart';

class ClassroomsHomeScreen extends ConsumerWidget {
  const ClassroomsHomeScreen({super.key});

  Future<void> _showAddClassroomDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    var isSubmitting = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogBuilderContext, setState) {
              return AlertDialog(
                title: const Text('Add Classroom'),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Classroom Name',
                          hintText: 'Enter classroom name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Classroom name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: ageController,
                        decoration: const InputDecoration(
                          labelText: 'Age of Members',
                          hintText: 'Enter age range',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Age of members is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: Text(l10n.cancel),
                  ),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setState(() => isSubmitting = true);
                            try {
                              await ref.read(classroomRepositoryProvider).add(
                                    ClassroomAddDto(
                                      name: nameController.text.trim(),
                                      ageOfMembers: ageController.text.trim(),
                                    ),
                                  );
                              ref.invalidate(visibleClassroomsProvider);
                              if (context.mounted) {
                                Navigator.of(dialogContext).pop();
                                showSuccessSnackbar(
                                  context,
                                  'Classroom added successfully.',
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                showErrorSnackbar(context, e.toString());
                              }
                            } finally {
                              if (dialogBuilderContext.mounted) {
                                setState(() => isSubmitting = false);
                              }
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      ageController.dispose();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final roleAsync = ref.watch(currentUserRoleProvider);
    final classroomsAsync = ref.watch(visibleClassroomsProvider);
    final role = roleAsync.valueOrNull;
    final isAdmin = role == 'admin';
    final pendingServantsAsync =
        isAdmin ? ref.watch(pendingServantsProvider) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.visibleClassrooms),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add Classroom',
              onPressed: () => _showAddClassroomDialog(context, ref, l10n),
            ),
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
          if (isAdmin) {
            ref.invalidate(pendingServantsProvider);
            try {
              await ref.read(pendingServantsProvider.future);
            } catch (e, s) {
              developer.log(
                'Failed refreshing pending servants',
                name: 'ClassroomsHomeScreen',
                error: e,
                stackTrace: s,
              );
            }
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Pending Servants (admin only) ─────────────────────────────
            if (isAdmin)
              _PendingServantsCard(pendingServantsAsync: pendingServantsAsync),

            // ── Classrooms section ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.class_, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.visibleClassrooms,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            classroomsAsync.when(
              data: (classrooms) {
                if (classrooms.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.class_outlined,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            l10n.noClassrooms,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: classrooms
                      .map(
                        (c) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Icon(
                                Icons.class_,
                                color:
                                    Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                            title: Text(
                              c.name ?? '-',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Age: ${c.ageOfMembers ?? '-'} • Members: ${c.totalMembersCount ?? 0}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push(
                              AppRoutes.classroomDetail,
                              extra: c,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(visibleClassroomsProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingServantsCard extends StatelessWidget {
  final AsyncValue<List<PendingUserDto>>? pendingServantsAsync;

  const _PendingServantsCard({required this.pendingServantsAsync});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                Icons.pending_actions,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.pendingServants,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  pendingServantsAsync!.when(
                    data: (list) => Text(
                      '${list.length} pending',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: list.isNotEmpty
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                    loading: () => const Text('Loading...'),
                    error: (e, _) => Text('Failed: $e'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
