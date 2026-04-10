import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../providers/members_providers.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../../shared/widgets/app_section_bottom_navigation_bar.dart';
import '../../../core/l10n/app_localizations.dart';

class MembersListScreen extends ConsumerWidget {
  const MembersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final membersAsync = ref.watch(membersListProvider);
    final role = ref.watch(currentUserRoleProvider).valueOrNull;
    final homeRoute = AuthRoleUtils.routeForRole(role);
    final currentLocation = GoRouterState.of(context).matchedLocation;

    return PopScope(
      canPop: currentLocation == homeRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go(homeRoute);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.members)),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await context.push('/members/add');
            ref.invalidate(membersListProvider);
          },
          child: const Icon(Icons.add),
        ),
        body: membersAsync.when(
          loading: () => const cw.LoadingWidget(),
          error: (e, _) => cw.AppErrorWidget(
            message: e.toString(),
            onRetry: () => ref.invalidate(membersListProvider),
          ),
          data: (members) {
            if (members.isEmpty) {
              return cw.EmptyWidget(
                message: l10n.noMembers,
                icon: Icons.group,
              );
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(membersListProvider),
              child: ListView.builder(
                // bottom: 88 = FAB height (56) + top margin (16) + bottom margin (16)
                padding: const EdgeInsets.only(top: 8, bottom: 88),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF4299E1),
                        child: Text(
                          (member.fullName?.isNotEmpty == true)
                              ? member.fullName![0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(member.fullName ?? 'Unknown'),
                      subtitle: Text(member.gender ?? ''),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await context.push('/member/${member.id}');
                        ref.invalidate(membersListProvider);
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
        bottomNavigationBar: AppSectionBottomNavigationBar(
          currentIndex: 1,
          homeRoute: homeRoute,
        ),
      ),
    );
  }
}
