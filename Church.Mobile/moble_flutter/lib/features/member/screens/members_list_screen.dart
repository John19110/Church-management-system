import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../../custom_field/providers/custom_field_cache_providers.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../providers/members_providers.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../../shared/widgets/app_section_bottom_navigation_bar.dart';
import '../../../shared/widgets/app_list_row.dart';
import '../../../shared/widgets/app_search_field.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/app_network_avatar.dart';

class MembersListScreen extends ConsumerStatefulWidget {
  /// When non-null the screen shows only members of the specified meeting
  /// and its title reflects the meeting context.
  final int? meetingId;
  final String? meetingName;

  const MembersListScreen({super.key, this.meetingId, this.meetingName});

  @override
  ConsumerState<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends ConsumerState<MembersListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  bool get _isMeetingScoped => widget.meetingId != null;

  void _invalidate() {
    if (_isMeetingScoped) {
      ref.invalidate(membersByMeetingProvider(widget.meetingId!));
    } else {
      ref.invalidate(membersListProvider);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final membersAsync = _isMeetingScoped
        ? ref.watch(membersByMeetingProvider(widget.meetingId!))
        : ref.watch(membersListProvider);
    final roleAsync = ref.watch(currentUserRoleProvider);
    final homeRoute = AuthRoleUtils.routeForRole(roleAsync.valueOrNull);

    // When in meeting context: always allow natural pop (back to meeting detail).
    // When navigated to as a root tab: replicate the original canPop logic.
    final currentLocation =
        _isMeetingScoped ? null : GoRouterState.of(context).matchedLocation;
    final canPop =
        _isMeetingScoped ? true : (currentLocation == homeRoute);

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
        // Only reached when canPop == false (general tab, non-home location).
        context.go(homeRoute);
      },
      child: roleAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: Text(buildTitle())),
          body: const cw.LoadingWidget(),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: Text(buildTitle())),
          body: cw.AppErrorWidget(message: e.toString()),
        ),
        data: (role) => Scaffold(
          appBar: AppBar(
            title: Text(buildTitle()),
            actions: [
              if (!_isMeetingScoped && AuthRoleUtils.canManageCustomFields(role))
                IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: l10n.manageCustomFields,
                  onPressed: () async {
                    await context.push('/custom-fields/Member');
                    if (context.mounted) {
                      refreshEntityFormsAfterDefinitionChange(
                        ref,
                        UnifiedEntityNames.member,
                      );
                    }
                  },
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              await context.push('/members/add');
              _invalidate();
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.add),
          ),
          body: membersAsync.when(
            loading: () => const cw.LoadingWidget(),
            error: (e, _) => cw.AppErrorWidget(
              message: e.toString(),
              onRetry: _invalidate,
            ),
            data: (members) {
              if (members.isEmpty) {
                return cw.EmptyWidget(
                  message: l10n.noMembers,
                  icon: Icons.group_outlined,
                );
              }

              final query = _query.trim().toLowerCase();
              final filtered = query.isEmpty
                  ? members
                  : members
                      .where((m) =>
                          (m.fullName ?? '').toLowerCase().contains(query))
                      .toList();

              return RefreshIndicator(
                onRefresh: () async => _invalidate(),
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
                        controller: _searchController,
                        hint: l10n.searchMembers,
                        onChanged: (v) => setState(() => _query = v),
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
                                final name =
                                    member.fullName ?? l10n.unknownName;
                                final initial =
                                    (member.fullName?.isNotEmpty == true)
                                        ? member.fullName![0].toUpperCase()
                                        : '?';
                                return AppListRow(
                                  leading: AppNetworkAvatar(
                                    imageUrl: member.displayImageUrl,
                                    debugTag: 'members-list-${member.id}',
                                    radius: 24,
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    placeholder: Text(
                                      initial,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  title: name,
                                  subtitle: member.gender ?? '',
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
                                    _invalidate();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
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
