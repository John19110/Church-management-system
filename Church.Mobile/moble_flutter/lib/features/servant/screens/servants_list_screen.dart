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
import '../../../shared/widgets/app_list_row.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/app_network_avatar.dart';

class ServantsListScreen extends ConsumerWidget {
  /// When non-null the screen shows only servants of the specified meeting
  /// and its title reflects the meeting context.
  final int? meetingId;
  final String? meetingName;

  const ServantsListScreen({super.key, this.meetingId, this.meetingName});

  bool get _isMeetingScoped => meetingId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final servantsAsync = _isMeetingScoped
        ? ref.watch(servantsByMeetingProvider(meetingId!))
        : ref.watch(servantsListProvider);
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final homeRoute = AuthRoleUtils.routeForRole(role);

    void invalidate() {
      if (_isMeetingScoped) {
        ref.invalidate(servantsByMeetingProvider(meetingId!));
      } else {
        ref.invalidate(servantsListProvider);
      }
    }

    String buildTitle() {
      final base = l10n.servants;
      if (_isMeetingScoped && meetingName != null) {
        return '$base — $meetingName';
      }
      return base;
    }

    // When meeting-scoped, allow natural pop back to meeting detail.
    // When navigated to as a root tab, keep the original forced-home behavior.
    return PopScope(
      canPop: _isMeetingScoped,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go(homeRoute);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(buildTitle()),
          actions: [
            if (!_isMeetingScoped && role == 'superadmin')
              IconButton(
                icon: const Icon(Icons.pending_actions),
                tooltip: l10n.pendingUsers,
                onPressed: () => context.push(AppRoutes.pendingUsers),
              ),
            if (!_isMeetingScoped && role == 'admin')
              IconButton(
                icon: const Icon(Icons.pending_actions),
                tooltip: l10n.pendingUsers,
                onPressed: () => context.push(AppRoutes.adminPendingUsers),
              ),
            if (!_isMeetingScoped &&
                (role == 'admin' || role == 'superadmin'))
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
            onRetry: invalidate,
          ),
          data: (servants) {
            if (servants.isEmpty) {
              return cw.EmptyWidget(
                message: l10n.noServants,
                icon: Icons.people,
              );
            }
            return RefreshIndicator(
              onRefresh: () async => invalidate(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                itemCount: servants.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final servant = servants[index];
                  final initial = (servant.name?.isNotEmpty == true)
                      ? servant.name![0].toUpperCase()
                      : '?';
                  return AppListRow(
                    key: ValueKey('servant-${servant.id}'),
                    leading: AppNetworkAvatar(
                      imageUrl: servant.displayImageUrl,
                      radius: 24,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      placeholder: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: servant.name ?? l10n.unknownName,
                    subtitle: servant.phoneNumber ?? '',
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
                      invalidate();
                    },
                  );
                },
              ),
            );
          },
        ),
        bottomNavigationBar: _isMeetingScoped
            ? null
            : AppSectionBottomNavigationBar(
                currentIndex: 2,
                homeRoute: homeRoute,
              ),
      ),
    );
  }
}
