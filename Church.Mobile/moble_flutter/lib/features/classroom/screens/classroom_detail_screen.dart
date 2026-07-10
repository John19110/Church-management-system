import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/app_network_avatar.dart';
import '../../member/models/member_models.dart';
import '../../member/providers/members_providers.dart';
import '../models/classroom_models.dart';
import '../providers/classroom_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../../custom_field/providers/custom_field_cache_providers.dart';
import '../../unified_form/providers/unified_form_providers.dart';
import '../../unified_form/utils/unified_form_field_utils.dart';
import '../../unified_form/widgets/entity_fields_empty_state.dart';
import '../../unified_form/widgets/unified_entity_form.dart';

/// Approximate height of the fixed bottom action bar (two buttons + spacing).
const double _kClassroomDetailBottomBarHeight = 132;

class ClassroomDetailScreen extends ConsumerWidget {
  final ClassroomReadDto classroom;

  const ClassroomDetailScreen({super.key, required this.classroom});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final classroomId = classroom.id;

    if (classroomId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.classroom)),
        body: Center(
          child: Text(l10n.classroomInvalidMissingId),
        ),
      );
    }

    final membersAsync = ref.watch(membersByClassroomProvider(classroomId));
    final formQuery = (
      entity: UnifiedEntityNames.classroom,
      id: classroomId,
    );
    final formAsync = ref.watch(entityFormDataProvider(formQuery));
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    Future<void> refreshClassroom() async {
      ref.invalidate(membersByClassroomProvider(classroomId));
      ref.invalidate(entityFormDataProvider(formQuery));
      await Future.wait([
        ref.read(membersByClassroomProvider(classroomId).future),
        ref.read(entityFormDataProvider(formQuery).future),
      ]);
    }

    final appBarTitle = formAsync.maybeWhen(
      data: (form) {
        final title = unifiedDisplayTitle(
          UnifiedEntityNames.classroom,
          form.fields,
          l10n: l10n,
        );
        return title == l10n.notAvailable
            ? (classroom.name ?? l10n.classroom)
            : title;
      },
      orElse: () => classroom.name ?? l10n.classroom,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: l10n.editEntityFields,
            onPressed: () async {
              final updated = await context.push<bool>(
                '/custom-fields/values/Classroom/$classroomId',
              );
              if (updated == true) {
                ref.invalidate(entityFormDataProvider(formQuery));
              }
            },
          ),
          if (AuthRoleUtils.canManageCustomFields(role))
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
                  ref.invalidate(entityFormDataProvider(formQuery));
                }
              },
            ),
          if (AuthRoleUtils.canDeleteClassroom(role))
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              tooltip: l10n.deleteClassroom,
              onPressed: () => _confirmDeleteClassroom(
                context,
                ref,
                classroomId: classroomId,
                meetingId: classroom.meetingId,
                l10n: l10n,
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: _kClassroomDetailBottomBarHeight + bottomInset,
        ),
        child: FloatingActionButton(
          onPressed: () async {
            final created = await context.push<int?>(
              '/members/add',
              extra: classroomId,
            );
            if (created != null && created > 0) {
              ref.invalidate(membersByClassroomProvider(classroomId));
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: refreshClassroom,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: AppCard(
                        child: Row(
                          children: [
                            Container(
                              height: 44,
                              width: 44,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.10),
                                borderRadius: AppRadius.smAll,
                              ),
                              child: Icon(
                                Icons.groups_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                l10n.membersCountLine(
                                    classroom.totalMembersCount ?? 0),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: formAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (form) {
                          if (form.fields.isEmpty) {
                            return EntityFieldsEmptyState(
                              entityName: UnifiedEntityNames.classroom,
                              canManageDefinitions:
                                  role == 'admin' || role == 'superadmin',
                            );
                          }
                          return UnifiedEntityDetailFields(
                            fields: form.fields,
                            entityName: UnifiedEntityNames.classroom,
                          );
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: SectionHeader(title: l10n.membersHeading),
                    ),
                  ),
                  ..._buildMembersSlivers(context, ref, l10n, membersAsync, classroomId),
                  // Space so last grid row / FAB are not hidden behind bottom bar
                  SliverPadding(
                    padding: EdgeInsets.only(
                      bottom: _kClassroomDetailBottomBarHeight + bottomInset + 72,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Material(
            elevation: 8,
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.push(
                        '${AppRoutes.attendanceTake}?classroomId=$classroomId',
                      ),
                      icon: const Icon(Icons.fact_check_outlined),
                      label: Text(l10n.takeAttendance),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => context.push(
                        '${AppRoutes.attendanceHistory}/$classroomId?classroomName=${Uri.encodeComponent(classroom.name ?? '')}',
                      ),
                      icon: const Icon(Icons.history),
                      label: Text(l10n.attendanceHistory),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _confirmDeleteClassroom(
    BuildContext context,
    WidgetRef ref, {
    required int classroomId,
    required int? meetingId,
    required AppLocalizations l10n,
  }) async {
    final confirmed = await cw.showConfirmDialog(
      context,
      title: l10n.deleteClassroom,
      content: l10n.confirmDeleteClassroom,
    );
    if (!confirmed) return;

    try {
      await ref.read(classroomRepositoryProvider).delete(classroomId);
      if (!context.mounted) return;
      invalidateVisibleClassrooms(ref, meetingId: meetingId);
      cw.showSuccessSnackbar(context, l10n.classroomDeletedSuccessfully);
      context.pop();
    } catch (e) {
      if (context.mounted) {
        cw.showErrorSnackbar(context, e.toString());
      }
    }
  }

  List<Widget> _buildMembersSlivers(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    AsyncValue<List<MemberReadDto>> membersAsync,
    int classroomId,
  ) {
    return membersAsync.when(
      loading: () => [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (e, _) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${l10n.couldNotLoadMembers} $e'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(membersByClassroomProvider(classroomId)),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ],
      data: (members) {
        if (members.isEmpty) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.noMembersInClassroomYet),
              ),
            ),
          ];
        }

        return [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final m = members[index];
                  final name = m.fullName?.trim().isNotEmpty == true
                      ? m.fullName!
                      : l10n.memberNumberLabel(m.id ?? 0);

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.push('/member/${m.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppNetworkAvatar(
                              imageUrl: m.displayImageUrl,
                              debugTag: 'classroom-grid-${m.id}',
                              radius: 40,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              placeholder: Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: members.length,
              ),
            ),
          ),
        ];
      },
    );
  }
}
