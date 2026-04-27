import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
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
  final int? meetingId;
  final String? meetingName;

  const ClassroomsHomeScreen({
    super.key,
    this.showAppBar = true,
    this.meetingId,
    this.meetingName,
  });

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
    if (widget.meetingId != null) {
      ref.invalidate(visibleClassroomsByMeetingProvider(widget.meetingId));
      await ref.read(visibleClassroomsByMeetingProvider(widget.meetingId).future);
    } else {
      ref.invalidate(visibleClassroomsProvider);
      await ref.read(visibleClassroomsProvider.future);
    }
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
            final l10n = AppLocalizations.of(dialogBuilderContext);
            return AlertDialog(
              title: Text(l10n.addClassroom),
              content: SingleChildScrollView(
                child: Form(
                  key: _classroomFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n.classroomNameLabel,
                          hintText: l10n.enterClassroomNameHint,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.classroomNameRequiredGeneric;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ageController,
                        decoration: InputDecoration(
                          labelText: l10n.ageOfMembersLabel,
                          hintText: l10n.enterAgeRangeHint,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.ageOfMembersRequiredGeneric;
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
                  child: Text(l10n.cancel),
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
                              l10n.classroomAddedSuccessfully,
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
                      : Text(l10n.add),
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
    final l10n = AppLocalizations.of(context);
    final roleAsync = ref.watch(currentUserRoleProvider);
    final classroomsAsync = widget.meetingId != null
        ? ref.watch(visibleClassroomsByMeetingProvider(widget.meetingId))
        : ref.watch(visibleClassroomsProvider);
    final role = roleAsync.resolvedRoleOrNull;
    final homeRoute = AuthRoleUtils.routeForRole(role);
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final canAddClassroom = role == 'admin';
    final title = widget.meetingName?.trim().isNotEmpty == true
        ? '${l10n.classrooms} — ${widget.meetingName}'
        : l10n.classroomsHome;

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
                title: Text(title),
                actions: [
                  if (canAddClassroom)
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: l10n.addClassroom,
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
                tooltip: l10n.addClassroom,
                child: const Icon(Icons.add),
              )
            : null,
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: classroomsAsync.when(
            data: (classrooms) {
              final filtered = widget.meetingId != null
                  ? classrooms
                      .where((c) => c.meetingId == widget.meetingId)
                      .toList()
                  : classrooms;
              return ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  !widget.showAppBar && canAddClassroom ? 88 : 16,
                ),
                children: [
                  Text(
                    l10n.visibleClassrooms,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l10n.noVisibleClassroomsFound),
                      ),
                    )
                  else
                    ...filtered.map(
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
                                  l10n.ageLabel.replaceAll(
                                    '{age}',
                                    c.ageOfMembers ?? '—',
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${c.totalMembersCount ?? 0} ${l10n.members} · '
                                  '${l10n.attendanceSessionsCount.replaceAll(
                                    '{count}',
                                    (c.pastAttendanceSessionsCount ?? 0).toString(),
                                  )}',
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
                Text(
                  l10n.visibleClassrooms,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('${l10n.failedToLoadVisibleClassrooms} $e'),
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
