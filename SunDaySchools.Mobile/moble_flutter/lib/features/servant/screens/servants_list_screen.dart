import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../../custom_field/providers/custom_field_cache_providers.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../providers/servants_providers.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../../shared/widgets/app_section_bottom_navigation_bar.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/app_network_avatar.dart';

class ServantsListScreen extends ConsumerWidget {
  const ServantsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final servantsAsync = ref.watch(servantsListProvider);
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final homeRoute = AuthRoleUtils.routeForRole(role);
    // Do NOT read GoRouterState.matchedLocation here. A context.push() updates
    // the router while this route stays in the stack; rebuilding this ListView
    // without item keys leaves stale parentData -> viewport semantics crash.

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go(homeRoute);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.servants),
          actions: [
            if (role == 'superadmin')
              IconButton(
                icon: const Icon(Icons.pending_actions),
                tooltip: l10n.pendingUsers,
                onPressed: () => context.push(AppRoutes.pendingUsers),
              ),
            if (role == 'admin' || role == 'superadmin')
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: l10n.manageCustomFields,
                onPressed: () async {
                  await context.push('/custom-fields/Servant');
                  if (context.mounted) {
                    refreshEntityFormsAfterDefinitionChange(
                      ref,
                      UnifiedEntityNames.servant,
                    );
                  }
                },
              ),
          ],
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
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                itemCount: servants.length,
                itemBuilder: (context, index) {
                  final servant = servants[index];
                  final initial = (servant.name?.isNotEmpty == true)
                      ? servant.name![0].toUpperCase()
                      : '?';
                  return Card(
                    key: ValueKey('servant-${servant.id}'),
                    child: ListTile(
                      leading: AppNetworkAvatar(
                        imageUrl: servant.displayImageUrl,
                        radius: 20,
                        backgroundColor: const Color(0xFFED8936),
                        placeholder: Text(
                          initial,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(servant.name ?? l10n.unknownName),
                      subtitle: Text(servant.phoneNumber ?? ''),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        if (servant.id <= 0) {
                          if (context.mounted) {
                            cw.showErrorSnackbar(
                              context,
                              l10n.servantIdMissingFromApi,
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
