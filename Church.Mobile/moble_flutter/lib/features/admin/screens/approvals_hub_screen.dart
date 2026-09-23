import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_content.dart';
import '../../../shared/widgets/app_section_navigation.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';

class ApprovalsHubScreen extends ConsumerWidget {
  const ApprovalsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final homeRoute = AuthRoleUtils.routeForRole(role);
    final canReview = role == 'admin' || role == 'superadmin';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go(homeRoute);
      },
      child: AppAdaptiveScaffold(
        destination: AppNavDestination.approvals,
        homeRoute: homeRoute,
        role: role,
        appBar: AppBar(title: Text(l10n.approvals)),
        body: !canReview
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    l10n.notAuthorized,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              )
            : ListView(
                padding: appPagePadding(context),
                children: [
                  Text(
                    l10n.approvalsSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (role == 'superadmin') ...[
                    _ApprovalTile(
                      icon: Icons.person_add_alt_1_outlined,
                      title: l10n.pendingUsers,
                      onTap: () => context.push(AppRoutes.pendingUsers),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ApprovalTile(
                      icon: Icons.admin_panel_settings_outlined,
                      title: l10n.pendingAdmins,
                      onTap: () => context.push(AppRoutes.pendingAdmins),
                    ),
                  ],
                  if (role == 'admin') ...[
                    _ApprovalTile(
                      icon: Icons.person_add_alt_1_outlined,
                      title: l10n.pendingUsers,
                      onTap: () => context.push(AppRoutes.adminPendingUsers),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ApprovalTile(
                      icon: Icons.volunteer_activism_outlined,
                      title: l10n.pendingServants,
                      onTap: () => context.push(AppRoutes.pendingServants),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ApprovalTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ApprovalTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      bordered: true,
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          AppIcons.chevronForward(
            context,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
