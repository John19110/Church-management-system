import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../member/models/member_models.dart';
import '../../member/providers/members_providers.dart';
import '../models/classroom_models.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../../custom_field/providers/custom_field_cache_providers.dart';
import '../../unified_form/providers/unified_form_providers.dart';
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
    final formAsync = ref.watch(
      entityFormDataProvider((entity: UnifiedEntityNames.classroom, id: classroomId)),
    );
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    Future<void> refreshMembers() async {
      ref.invalidate(membersByClassroomProvider(classroomId));
      await ref.read(membersByClassroomProvider(classroomId).future);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(classroom.name ?? l10n.classroom),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: l10n.editEntityFields,
            onPressed: () async {
              final updated = await context.push<bool>(
                '/custom-fields/values/Classroom/$classroomId',
              );
              if (updated == true) {
                ref.invalidate(
                  entityFormDataProvider((
                    entity: UnifiedEntityNames.classroom,
                    id: classroomId,
                  )),
                );
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
                }
              },
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: _kClassroomDetailBottomBarHeight + bottomInset,
        ),
        child: FloatingActionButton(
          onPressed: () => context.push('/members/add', extra: classroomId),
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: refreshMembers,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.ageGroupLabel.replaceAll(
                              '{age}',
                              classroom.ageOfMembers ?? '—',
                            ),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${classroom.totalMembersCount ?? 0} ${l10n.members} · '
                            '${l10n.pastAttendanceSessions.replaceAll(
                              '{count}',
                              (classroom.pastAttendanceSessionsCount ?? 0).toString(),
                            )}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          if (classroom.servantNames.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              l10n.servantsLabel.replaceAll(
                                '{names}',
                                classroom.servantNames.join(', '),
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
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
                          return UnifiedEntityDetailFields(fields: form.fields);
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        l10n.membersHeading,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
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
                      : l10n.memberNumber.replaceAll(
                          '{id}',
                          (m.id ?? '').toString(),
                        );

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.push('/member/${m.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              backgroundImage: m.imageUrl != null &&
                                      m.imageUrl!.isNotEmpty
                                  ? NetworkImage(m.imageUrl!)
                                  : null,
                              child: m.imageUrl == null || m.imageUrl!.isEmpty
                                  ? Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : '?',
                                      style:
                                          Theme.of(context).textTheme.titleLarge,
                                    )
                                  : null,
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
