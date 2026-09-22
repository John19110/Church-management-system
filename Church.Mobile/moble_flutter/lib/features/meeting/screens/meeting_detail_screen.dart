import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/app_section_bottom_navigation_bar.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../../shared/widgets/section_header.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../../auth/utils/auth_session.dart';
import '../../classroom/widgets/classrooms_list_section.dart';
import '../../servant/models/servant_models.dart';
import '../../servant/providers/servants_providers.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../../unified_form/providers/unified_form_providers.dart';
import '../../unified_form/utils/unified_form_field_utils.dart';
import '../../unified_form/widgets/entity_fields_empty_state.dart';
import '../../unified_form/widgets/unified_entity_detail_header.dart';
import '../../unified_form/widgets/unified_entity_form.dart';
import '../models/meeting_models.dart';
import '../providers/meeting_providers.dart';
import '../utils/meeting_delete_actions.dart';

class MeetingDetailScreen extends ConsumerWidget {
  final MeetingReadDto meeting;

  /// When true (Meeting Admin home), show section bottom nav and treat as home.
  final bool showSectionBottomNav;

  const MeetingDetailScreen({
    super.key,
    required this.meeting,
    this.showSectionBottomNav = false,
  });

  Future<void> _openMeetingSettings(
    BuildContext context,
    WidgetRef ref, {
    required int meetingId,
    required bool canEdit,
    required bool canDelete,
  }) async {
    final l10n = AppLocalizations.of(context);
    final formQuery = (
      entity: UnifiedEntityNames.meeting,
      id: meetingId,
    );

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  l10n.meetingSettings,
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(l10n.editMeeting),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final saved = await context.push<bool>(
                      '/meetings/$meetingId/edit',
                    );
                    if (saved == true && context.mounted) {
                      ref.invalidate(entityFormDataProvider(formQuery));
                      ref.invalidate(visibleMeetingsProvider);
                    }
                  },
                ),
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.visibility_outlined),
                  title: Text(l10n.memberViews),
                  subtitle: Text(
                    meeting.memberViewMode == MemberViewMode.allAndAssigned
                        ? l10n.memberViewAllAndAssignedTitle
                        : l10n.memberViewAssignedOnlyTitle,
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _editMemberViewMode(context, ref);
                  },
                ),
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.checklist_outlined),
                  title: Text(l10n.attendanceCriteria),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push(
                      '/meetings/$meetingId/attendance-criteria',
                      extra: meeting.name,
                    );
                  },
                ),
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.table_view_outlined),
                  title: Text(l10n.memberExcelSettingsTile),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push(
                      '/meetings/$meetingId/members/excel',
                      extra: meeting.name,
                    );
                  },
                ),
              if (canDelete)
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: Theme.of(sheetContext).colorScheme.error,
                  ),
                  title: Text(
                    l10n.deleteMeeting,
                    style: TextStyle(
                      color: Theme.of(sheetContext).colorScheme.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    confirmAndDeleteMeeting(
                      context,
                      ref,
                      meetingId: meetingId,
                      l10n: l10n,
                    );
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editMemberViewMode(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final meetingId = meeting.id;
    if (meetingId == null || meetingId <= 0) return;

    var selectedMode = meeting.memberViewMode;
    final selectedViewerIds = meeting.allMembersViewerServantIds.toSet();
    List<ServantReadDto> servants = const [];
    try {
      servants = await ref.read(servantsByMeetingProvider(meetingId).future);
    } catch (_) {
      servants = const [];
    }

    if (!context.mounted) return;

    final result = await showDialog<({MemberViewMode mode, List<int> viewerIds})>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.memberViews),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          selectedMode == MemberViewMode.assignedOnly
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                        ),
                        title: Text(l10n.memberViewAssignedOnlyTitle),
                        subtitle: Text(l10n.memberViewAssignedOnlyDesc),
                        onTap: () => setState(
                          () => selectedMode = MemberViewMode.assignedOnly,
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          selectedMode == MemberViewMode.allAndAssigned
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                        ),
                        title: Text(l10n.memberViewAllAndAssignedTitle),
                        subtitle: Text(l10n.memberViewAllAndAssignedDesc),
                        onTap: () => setState(
                          () => selectedMode = MemberViewMode.allAndAssigned,
                        ),
                      ),
                      if (selectedMode == MemberViewMode.allAndAssigned) ...[
                        const SizedBox(height: 12),
                        Text(
                          l10n.selectServantsForAllMembersView,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        if (servants.isEmpty)
                          Text(l10n.noServantsInMeetingYet)
                        else
                          ...servants.map((servant) {
                            final checked =
                                selectedViewerIds.contains(servant.id);
                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: checked,
                              title: Text(
                                servant.name?.trim().isNotEmpty == true
                                    ? servant.name!
                                    : l10n.unknownName,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    selectedViewerIds.add(servant.id);
                                  } else {
                                    selectedViewerIds.remove(servant.id);
                                  }
                                });
                              },
                            );
                          }),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop((
                    mode: selectedMode,
                    viewerIds: selectedViewerIds.toList(),
                  )),
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !context.mounted) return;

    final modeUnchanged = result.mode == meeting.memberViewMode;
    final viewersUnchanged = _sameIntSet(
      result.viewerIds,
      meeting.allMembersViewerServantIds,
    );
    if (modeUnchanged &&
        (result.mode == MemberViewMode.assignedOnly || viewersUnchanged)) {
      return;
    }

    try {
      await ref.read(meetingRepositoryProvider).update(
            meetingId,
            leaderServantId: meeting.leaderServantId,
            memberViewMode: result.mode,
            allMembersViewerServantIds: result.mode == MemberViewMode.assignedOnly
                ? const <int>[]
                : result.viewerIds,
          );
      ref.invalidate(visibleMeetingsProvider);
      if (context.mounted) {
        cw.showSuccessSnackbar(context, l10n.memberViewModeUpdated);
      }
    } catch (e) {
      if (context.mounted) {
        cw.showErrorSnackbar(context, userFriendlyMessage(e, l10n));
      }
    }
  }

  static bool _sameIntSet(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    final setA = a.toSet();
    return b.every(setA.contains);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final meetingId = meeting.id;
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final canEdit = AuthRoleUtils.canEditMeeting(role);
    final canManageFields = AuthRoleUtils.canManageCustomFields(role);
    final canDelete = AuthRoleUtils.canDeleteMeeting(role);
    final showManageFab = canEdit || canDelete;

    if (meetingId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.meetingDetails)),
        body: Center(child: Text(l10n.missingRequiredData)),
      );
    }

    final formQuery = (
      entity: UnifiedEntityNames.meeting,
      id: meetingId,
    );
    final formAsync = ref.watch(entityFormDataProvider(formQuery));

    final appBarTitle = formAsync.maybeWhen(
      data: (form) {
        final title = unifiedDisplayTitle(
          UnifiedEntityNames.meeting,
          form.fields,
          l10n: l10n,
        );
        return title == l10n.notAvailable
            ? (meeting.name ?? l10n.meetingDetails)
            : title;
      },
      orElse: () => meeting.name ?? l10n.meetingDetails,
    );

    final homeRoute = AuthRoleUtils.routeForRole(role);
    final currentLocation = GoRouterState.of(context).matchedLocation;

    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          if (showSectionBottomNav)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => logoutSession(ref, context),
            ),
        ],
      ),
      floatingActionButton: showManageFab
          ? FloatingActionButton(
              tooltip: l10n.meetingSettings,
              onPressed: () => _openMeetingSettings(
                context,
                ref,
                meetingId: meetingId,
                canEdit: canEdit,
                canDelete: canDelete,
              ),
              child: const Icon(Icons.settings_outlined),
            )
          : null,
      bottomNavigationBar: showSectionBottomNav
          ? AppSectionBottomNavigationBar(
              currentIndex: 0,
              homeRoute: homeRoute,
            )
          : null,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          showManageFab ? 88 : 16,
        ),
        children: [
          formAsync.when(
            loading: () => const cw.LoadingWidget(useSkeleton: true),
            error: (e, _) => cw.AppErrorWidget(
              message: userFriendlyMessage(e, l10n),
              onRetry: () => ref.invalidate(entityFormDataProvider(formQuery)),
            ),
            data: (form) {
              final visible = visibleUnifiedFields(
                form.fields,
                entityName: UnifiedEntityNames.meeting,
                l10n: l10n,
              );
              if (visible.isEmpty) {
                return EntityFieldsEmptyState(
                  entityName: UnifiedEntityNames.meeting,
                  canManageDefinitions: canManageFields,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UnifiedEntityDetailHeader(
                    entityName: UnifiedEntityNames.meeting,
                    fields: form.fields,
                    eyebrow: l10n.meetingDetails,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  UnifiedEntityDetailFields(
                    entityName: UnifiedEntityNames.meeting,
                    fields: form.fields,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title:
                '${l10n.servants} (${l10n.formatInteger(meeting.servantNames.length)})',
          ),
          _NameChips(names: meeting.servantNames, l10n: l10n),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title:
                '${l10n.membersHeading} (${l10n.formatInteger(meeting.memberNames.length)})',
          ),
          _NameChips(names: meeting.memberNames, l10n: l10n),
          const SizedBox(height: AppSpacing.lg),
          if (meeting.hasClassrooms) ...[
            SectionHeader(title: l10n.classrooms),
            ClassroomsListSection(
              meetingId: meetingId,
              canAddClassroom: role == 'admin' || role == 'superadmin',
            ),
            const SizedBox(height: AppSpacing.xl),
          ] else ...[
            SectionHeader(title: l10n.meetingAttendance),
            ElevatedButton.icon(
              onPressed: () => context.push(
                '${AppRoutes.attendanceTake}?meetingId=$meetingId',
              ),
              icon: const Icon(Icons.fact_check_outlined),
              label: Text(l10n.takeAttendance),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => context.push(
                '${AppRoutes.attendanceHistory}/meeting/$meetingId',
                extra: meeting.name,
              ),
              icon: const Icon(Icons.history),
              label: Text(l10n.attendanceHistory),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          ElevatedButton.icon(
            onPressed: () => context.push(
              '/meetings/$meetingId/members',
              extra: meeting,
            ),
            icon: const Icon(Icons.group_add),
            label: Text(l10n.addUpdateRemoveMembers),
          ),
          if (role == 'admin' || role == 'superadmin') ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push(
                '/meetings/$meetingId/servants',
                extra: meeting.name,
              ),
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(l10n.manageServants),
            ),
          ],
        ],
      ),
    );

    if (!showSectionBottomNav) return scaffold;

    return PopScope(
      canPop: currentLocation == homeRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go(homeRoute);
      },
      child: scaffold,
    );
  }
}

/// Modern chip wrap for a list of people (servants / members).
class _NameChips extends StatelessWidget {
  final List<String> names;
  final AppLocalizations l10n;

  const _NameChips({required this.names, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (names.isEmpty) {
      return Text(
        l10n.notAvailable,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: palette.textTertiary),
      );
    }

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final name in names)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: palette.neutralSoft,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline,
                    size: 15, color: palette.textSecondary),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
