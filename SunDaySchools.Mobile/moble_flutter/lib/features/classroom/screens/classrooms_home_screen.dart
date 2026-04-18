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

class ClassroomsHomeScreen extends ConsumerStatefulWidget {
  /// When false, no [AppBar] is shown so this screen can be embedded under a
  /// parent [Scaffold] (e.g. Servant/Admin home) without a duplicate top bar.
  /// Add-classroom for admins uses a FAB in that case.
  final bool showAppBar;

  const ClassroomsHomeScreen({super.key, this.showAppBar = true});

  @override
  ConsumerState<ClassroomsHomeScreen> createState() =>
      _ClassroomsHomeScreenState();
}

class _ClassroomsHomeScreenState extends ConsumerState<ClassroomsHomeScreen> {
  final _classroomFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _resetAddClassroomDialog() {
    _nameController.clear();
    _ageController.clear();
  }

  Future<void> _refresh() async {
    ref.invalidate(visibleClassroomsProvider);
    await ref.read(visibleClassroomsProvider.future);
  }

  Future<void> _addClassroom() async {
    await ref.read(classroomRepositoryProvider).add(
          ClassroomAddDto(
            name: _nameController.text.trim(),
            ageOfMembers: _ageController.text.trim(),
          ),
        );
    ref.invalidate(visibleClassroomsProvider);
  }

  Future<void> _showAddClassroomDialog() async {
    _resetAddClassroomDialog();
    var isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogBuilderContext, setDialogState) {
            return AlertDialog(
              title: const Text('Add Classroom'),
              content: SingleChildScrollView(
                child: Form(
                  key: _classroomFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
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
                        controller: _ageController,
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
                          if (!_classroomFormKey.currentState!.validate()) return;
                          if (!dialogBuilderContext.mounted) return;
                          setDialogState(() => isSubmitting = true);
                          try {
                            await _addClassroom();
                            if (!mounted || !dialogBuilderContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            showSuccessSnackbar(
                              context,
                              'Classroom added successfully.',
                            );
                          } catch (e) {
                            if (!mounted) return;
                            showErrorSnackbar(context, e.toString());
                          } finally {
                            if (dialogBuilderContext.mounted) {
                              setDialogState(() => isSubmitting = false);
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
  }

  @override
  Widget build(BuildContext context) {
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
        primary: widget.showAppBar,
        appBar: widget.showAppBar
            ? AppBar(
                title: const Text('Classrooms Home'),
                actions: [
                  if (canAddClassroom)
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Add Classroom',
                      onPressed: _showAddClassroomDialog,
                    ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => logoutSession(ref, context),
                  ),
                ],
              )
            : null,
        floatingActionButton: !widget.showAppBar && canAddClassroom
            ? FloatingActionButton(
                onPressed: _showAddClassroomDialog,
                tooltip: 'Add Classroom',
                child: const Icon(Icons.add),
              )
            : null,
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: classroomsAsync.when(
            data: (classrooms) {
              return ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  !widget.showAppBar && canAddClassroom ? 88 : 16,
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
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => context.push(
                            AppRoutes.classroomDetail,
                            extra: c,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      child: Icon(
                                        Icons.class_,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        c.name ?? '-',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Age: ${c.ageOfMembers ?? '—'}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${c.totalMembersCount ?? 0} members · '
                                  '${c.pastAttendanceSessionsCount ?? 0} attendance sessions',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
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
                !widget.showAppBar && canAddClassroom ? 88 : 16,
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
                !widget.showAppBar && canAddClassroom ? 88 : 16,
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
