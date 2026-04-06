import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;
import '../../../core/routing/app_router.dart';
import '../../../core/storage/token_storage.dart';
import '../../admin/providers/admin_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../models/classroom_models.dart';
import '../providers/classroom_providers.dart';

class ClassroomsHomeScreen extends ConsumerWidget {
  const ClassroomsHomeScreen({super.key});

  Future<void> _showAddClassroomDialog(BuildContext context, WidgetRef ref) async {
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
                    child: const Text('Cancel'),
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
          if (canViewPendingServants)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add Classroom',
              onPressed: () => _showAddClassroomDialog(context, ref),
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
          if (canViewPendingServants) {
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
