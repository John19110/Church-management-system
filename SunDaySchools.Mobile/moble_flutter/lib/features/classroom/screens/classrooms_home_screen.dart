import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/startup/deferred_startup_mixin.dart';
import '../../../core/routing/app_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../../auth/utils/auth_session.dart';
import '../../../shared/widgets/app_section_bottom_navigation_bar.dart';
import '../../custom_field/providers/custom_field_cache_providers.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../models/classroom_models.dart';
import '../providers/classroom_providers.dart';
import '../../meeting/utils/meeting_delete_actions.dart';

class ClassroomsHomeScreen extends ConsumerStatefulWidget {
  /// When false, no [AppBar] is shown so this screen can be embedded under a
  /// parent [Scaffold] (e.g. Servant/Admin home) without a duplicate top bar.
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

class _ClassroomsHomeScreenState extends ConsumerState<ClassroomsHomeScreen>
    with DeferredStartupMixin {
  Future<void> _refresh() async {
    invalidateVisibleClassrooms(ref, meetingId: widget.meetingId);
    try {
      if (widget.meetingId != null) {
        await ref.read(visibleClassroomsByMeetingProvider(widget.meetingId).future);
      } else {
        await ref.read(visibleClassroomsProvider.future);
      }
    } catch (_) {
      // AsyncValue on the list shows the error.
    }
  }

  Future<void> _openAddClassroom() async {
    await context.push(
      '/classrooms/add',
      extra: widget.meetingId,
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final roleAsync = ref.watch(currentUserRoleProvider);
    final classroomsAsync = !deferredReady
        ? const AsyncValue<List<ClassroomReadDto>>.loading()
        : widget.meetingId != null
            ? ref.watch(visibleClassroomsByMeetingProvider(widget.meetingId))
            : ref.watch(visibleClassroomsProvider);
    final role = roleAsync.resolvedRoleOrNull;
    final homeRoute = AuthRoleUtils.routeForRole(role);
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final canAddClassroom = role == 'admin' || role == 'superadmin';
    final canDeleteMeeting =
        AuthRoleUtils.canDeleteMeeting(role) &&
        widget.meetingId != null &&
        widget.meetingId! > 0;
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
                  if (role == 'admin' || role == 'superadmin')
                    IconButton(
                      icon: const Icon(Icons.tune),
                      tooltip: l10n.manageCustomFields,
                      onPressed: () async {
                        await context.push('/custom-fields/Classroom');
                        if (context.mounted) {
                          refreshEntityFormsAfterDefinitionChange(
                            ref,
                            UnifiedEntityNames.classroom,
                          );
                        }
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => logoutSession(ref, context),
                  ),
                ],
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
                padding: const EdgeInsets.all(16),
                children: [
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
                                        c.name ?? l10n.notAvailable,
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
                                  l10n.ageLabelText(c.ageOfMembers),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.membersAndSessionsLine(
                                    c.totalMembersCount ?? 0,
                                    c.pastAttendanceSessionsCount ?? 0,
                                  ),
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
              padding: const EdgeInsets.all(16),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
            error: (e, _) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canAddClassroom)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _openAddClassroom,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addClassroom),
                    ),
                  ),
                ),
              ),
            if (canDeleteMeeting)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => confirmAndDeleteMeeting(
                        context,
                        ref,
                        meetingId: widget.meetingId!,
                        l10n: l10n,
                        onDeleted: () => context.go(homeRoute),
                      ),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: Text(
                        l10n.deleteMeeting,
                        style: const TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),
            AppSectionBottomNavigationBar(
              currentIndex: 0,
              homeRoute: homeRoute,
            ),
          ],
        ),
      ),
    );
  }
}
