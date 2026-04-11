import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../providers/servants_providers.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../../shared/widgets/app_section_bottom_navigation_bar.dart';
import '../../../core/l10n/app_localizations.dart';

class ServantsListScreen extends ConsumerWidget {
  const ServantsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final servantsAsync = ref.watch(servantsListProvider);
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final homeRoute = AuthRoleUtils.routeForRole(role);
    final currentLocation = GoRouterState.of(context).matchedLocation;

    return PopScope(
      canPop: currentLocation == homeRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go(homeRoute);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.servants)),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await context.push('/servants/add');
            ref.invalidate(servantsListProvider);
          },
          child: const Icon(Icons.add),
        ),
        body: servantsAsync.when(
          loading: () => const cw.LoadingWidget(),
          error: (e, _) => cw.AppErrorWidget(
            message: e.toString(),
            onRetry: () => ref.invalidate(servantsListProvider),
          ),
          data: (servants) {
            if (servants.isEmpty) {
              return cw.EmptyWidget(
                message: l10n.noServants,
                icon: Icons.people,
              );
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(servantsListProvider),
              child: ListView.builder(
                // bottom: 88 = FAB height (56) + top margin (16) + bottom margin (16)
                padding: const EdgeInsets.only(top: 8, bottom: 88),
                itemCount: servants.length,
                itemBuilder: (context, index) {
                  final servant = servants[index];
                  return Card(
                    child: ListTile(
                      leading: servant.imageUrl != null
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(servant.imageUrl!),
                            )
                          : CircleAvatar(
                              backgroundColor: const Color(0xFFED8936),
                              child: Text(
                                (servant.name?.isNotEmpty == true)
                                    ? servant.name![0].toUpperCase()
                                    : '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                      title: Text(servant.name ?? 'Unknown'),
                      subtitle: Text(servant.phoneNumber ?? ''),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        if (servant.id <= 0) {
                          if (context.mounted) {
                            cw.showErrorSnackbar(
                              context,
                              'Servant id is missing from the server response. '
                              'The API must include an `id` field on each servant.',
                            );
                          }
                          return;
                        }
                        await context.push('/servants/${servant.id}');
                        ref.invalidate(servantsListProvider);
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
        bottomNavigationBar: AppSectionBottomNavigationBar(
          currentIndex: 2,
          homeRoute: homeRoute,
        ),
      ),
    );
  }
}
