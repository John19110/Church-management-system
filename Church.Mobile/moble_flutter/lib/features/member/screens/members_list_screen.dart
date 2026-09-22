import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../../meeting/models/meeting_models.dart';
import '../providers/members_providers.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../../shared/widgets/app_section_bottom_navigation_bar.dart';
import '../../../shared/widgets/app_list_row.dart';
import '../../../shared/widgets/app_search_field.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/app_network_avatar.dart';
import '../models/member_models.dart';

class MembersListScreen extends ConsumerStatefulWidget {
  /// When non-null the screen shows only members of the specified meeting
  /// and its title reflects the meeting context.
  final int? meetingId;
  final String? meetingName;
  final bool hasClassrooms;
  final MemberViewMode memberViewMode;
  final bool canViewAllMembers;

  const MembersListScreen({
    super.key,
    this.meetingId,
    this.meetingName,
    this.hasClassrooms = true,
    this.memberViewMode = MemberViewMode.assignedOnly,
    this.canViewAllMembers = false,
  });

  @override
  ConsumerState<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends ConsumerState<MembersListScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _query = '';
  TabController? _tabController;

  bool get _isMeetingScoped => widget.meetingId != null;

  bool get _showDualViews =>
      _isMeetingScoped &&
      widget.memberViewMode == MemberViewMode.allAndAssigned &&
      widget.canViewAllMembers;

  void _invalidate() {
    if (_isMeetingScoped) {
      ref.invalidate(membersByMeetingProvider(widget.meetingId!));
      ref.invalidate(allMembersByMeetingProvider(widget.meetingId!));
      ref.invalidate(assignedMembersByMeetingProvider(widget.meetingId!));
    } else {
      ref.invalidate(membersListProvider);
    }
  }

  @override
  void initState() {
    super.initState();
    if (_showDualViews) {
      _tabController = TabController(length: 2, vsync: this);
    }
  }

  @override
  void didUpdateWidget(covariant MembersListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldShow = widget.meetingId != null &&
        widget.memberViewMode == MemberViewMode.allAndAssigned &&
        widget.canViewAllMembers;
    if (shouldShow && _tabController == null) {
      _tabController = TabController(length: 2, vsync: this);
    } else if (!shouldShow && _tabController != null) {
      _tabController!.dispose();
      _tabController = null;
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final roleAsync = ref.watch(currentUserRoleProvider);
    final homeRoute = AuthRoleUtils.routeForRole(roleAsync.valueOrNull);

    final currentLocation = _isMeetingScoped
        ? null
        : GoRouterState.of(context).matchedLocation;
    final canPop = _isMeetingScoped ? true : (currentLocation == homeRoute);

    String buildTitle() {
      final base = l10n.members;
      if (_isMeetingScoped && widget.meetingName != null) {
        return '$base — ${widget.meetingName}';
      }
      return base;
    }

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go(homeRoute);
      },
      child: roleAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: Text(buildTitle())),
          body: const cw.LoadingWidget(useSkeleton: true),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: Text(buildTitle())),
          body: cw.AppErrorWidget(message: userFriendlyMessage(e, l10n)),
        ),
        data: (role) => Scaffold(
          appBar: AppBar(
            title: Text(buildTitle()),
            bottom: _showDualViews && _tabController != null
                ? TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: l10n.allMeetingMembers),
                      Tab(text: l10n.myAssignedMembers),
                    ],
                  )
                : null,
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              if (_isMeetingScoped) {
                await context.push(
                  '/members/add?meetingId=${widget.meetingId}',
                );
              } else {
                await context.push('/members/add');
              }
              _invalidate();
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.add),
          ),
          body: _showDualViews && _tabController != null
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _MembersListBody(
                      membersAsync: ref.watch(
                        allMembersByMeetingProvider(widget.meetingId!),
                      ),
                      searchController: _searchController,
                      query: _query,
                      onQueryChanged: (v) => setState(() => _query = v),
                      onRetry: _invalidate,
                      showClassroom: widget.hasClassrooms,
                      l10n: l10n,
                    ),
                    _MembersListBody(
                      membersAsync: ref.watch(
                        assignedMembersByMeetingProvider(widget.meetingId!),
                      ),
                      searchController: _searchController,
                      query: _query,
                      onQueryChanged: (v) => setState(() => _query = v),
                      onRetry: _invalidate,
                      showClassroom: widget.hasClassrooms,
                      l10n: l10n,
                    ),
                  ],
                )
              : _MembersListBody(
                  membersAsync: _isMeetingScoped
                      ? ref.watch(
                          assignedMembersByMeetingProvider(widget.meetingId!),
                        )
                      : ref.watch(membersListProvider),
                  searchController: _searchController,
                  query: _query,
                  onQueryChanged: (v) => setState(() => _query = v),
                  onRetry: _invalidate,
                  showClassroom: _isMeetingScoped && widget.hasClassrooms,
                  l10n: l10n,
                ),
          bottomNavigationBar: _isMeetingScoped
              ? null
              : AppSectionBottomNavigationBar(
                  currentIndex: 1,
                  homeRoute: homeRoute,
                ),
        ),
      ),
    );
  }
}

class _MembersListBody extends StatelessWidget {
  final AsyncValue<List<MemberReadDto>> membersAsync;
  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final void Function() onRetry;
  final bool showClassroom;
  final AppLocalizations l10n;

  const _MembersListBody({
    required this.membersAsync,
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
    required this.onRetry,
    required this.showClassroom,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return membersAsync.when(
      loading: () => const cw.LoadingWidget(useSkeleton: true),
      error: (e, _) => cw.AppErrorWidget(
        message: userFriendlyMessage(e, l10n),
        onRetry: onRetry,
      ),
      data: (members) {
        if (members.isEmpty) {
          return cw.EmptyWidget(
            message: l10n.noMembers,
            icon: Icons.group_outlined,
          );
        }

        final normalized = query.trim().toLowerCase();
        final filtered = normalized.isEmpty
            ? members
            : members
                .where(
                  (m) => (m.fullName ?? '').toLowerCase().contains(normalized),
                )
                .toList();

        return RefreshIndicator(
          onRefresh: () async => onRetry(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: AppSearchField(
                  controller: searchController,
                  hint: l10n.searchMembers,
                  onChanged: onQueryChanged,
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? cw.EmptyWidget(
                        message: l10n.noMembers,
                        icon: Icons.search_off,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.xs,
                          AppSpacing.md,
                          96,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, index) {
                          final member = filtered[index];
                          member.debugLogImage('members-list');
                          final name = member.fullName ?? l10n.unknownName;
                          final initial = (member.fullName?.isNotEmpty == true)
                              ? member.fullName![0].toUpperCase()
                              : '?';
                          final classroomLabel =
                              showClassroom &&
                                  (member.classroomName?.trim().isNotEmpty ??
                                      false)
                              ? '${l10n.classroom}: ${member.classroomName}'
                              : null;
                          final subtitleParts = <String>[
                            if (classroomLabel != null) classroomLabel,
                            if ((member.gender ?? '').trim().isNotEmpty)
                              member.gender!.trim(),
                          ];
                          return AppListRow(
                            leading: AppNetworkAvatar(
                              imageUrl: member.displayImageUrl,
                              debugTag: 'members-list-${member.id}',
                              radius: 24,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              placeholder: Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            title: name,
                            subtitle: subtitleParts.join(' · '),
                            onTap: () async {
                              if (member.id <= 0) {
                                if (context.mounted) {
                                  cw.showErrorSnackbar(
                                    context,
                                    l10n.memberIdMissingFromApi,
                                  );
                                }
                                return;
                              }
                              await context.push('/member/${member.id}');
                              onRetry();
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
