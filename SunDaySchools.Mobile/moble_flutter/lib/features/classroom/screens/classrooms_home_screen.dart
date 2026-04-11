import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../../auth/utils/auth_session.dart';
import '../../../shared/widgets/app_section_bottom_navigation_bar.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../models/classroom_models.dart';
import '../providers/classroom_providers.dart';

class ClassroomsHomeScreen extends ConsumerWidget {
  /// When false, no [AppBar] is shown so this screen can be embedded under a
  /// parent [Scaffold] (e.g. Servant/Admin home) without a duplicate top bar.
  /// Add-classroom for admins uses a FAB in that case.
  final bool showAppBar;

  const ClassroomsHomeScreen({super.key, this.showAppBar = true});

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
    final role = roleAsync.resolvedRoleOrNull;
    final homeRoute = AuthRoleUtils.routeForRole(role);
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final canAddClassroom = role == 'admin';

    return PopScope(
      canPop: currentLocation == homeRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go(homeRoute);
      },
      child: Scaffold(
        primary: showAppBar,
        appBar: showAppBar
            ? AppBar(
                title: const Text('Classrooms Home'),
                actions: [
                  if (canAddClassroom)
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Add Classroom',
                      onPressed: () => _showAddClassroomDialog(context, ref),
                    ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => logoutSession(ref, context),
                  ),
                ],
              )
            : null,
        floatingActionButton: !showAppBar && canAddClassroom
            ? FloatingActionButton(
                onPressed: () => _showAddClassroomDialog(context, ref),
                tooltip: 'Add Classroom',
                child: const Icon(Icons.add),
              )
            : null,
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(visibleClassroomsProvider);
            await ref.read(visibleClassroomsProvider.future);
          },
          child: classroomsAsync.when(
            data: (classrooms) {
              return ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  !showAppBar && canAddClassroom ? 88 : 16,
                ),
                children: [
                  const Text(
                    'Visible Classrooms',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (classrooms.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No visible classrooms found.'),
                      ),
                    )
                  else
                    ...classrooms.map(
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
                    ),
                ],
              );
            },
            loading: () => ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                !showAppBar && canAddClassroom ? 88 : 16,
              ),
              children: const [
                Text(
                  'Visible Classrooms',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
            error: (e, _) => ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                !showAppBar && canAddClassroom ? 88 : 16,
              ),
              children: [
                const Text(
                  'Visible Classrooms',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Failed to load visible classrooms: $e'),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: AppSectionBottomNavigationBar(
          currentIndex: 0,
          homeRoute: homeRoute,
        ),
      ),
    );
  }
}
