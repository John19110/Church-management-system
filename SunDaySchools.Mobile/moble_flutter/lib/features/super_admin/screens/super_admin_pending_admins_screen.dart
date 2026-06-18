import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../models/super_admin_models.dart';
import '../providers/super_admin_providers.dart';

class SuperAdminPendingAdminsScreen extends ConsumerWidget {
  const SuperAdminPendingAdminsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pendingAsync = ref.watch(pendingAdminsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pendingAdmins)),
      body: pendingAsync.when(
        loading: () => const cw.LoadingWidget(),
        error: (e, _) => cw.AppErrorWidget(
          message: userFriendlyMessage(e, l10n),
          onRetry: () => ref.invalidate(pendingAdminsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return cw.EmptyWidget(
              message: l10n.noPendingAdmins,
              icon: Icons.admin_panel_settings,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(pendingAdminsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final u = list[index];
                return _PendingAdminCard(
                  key: ValueKey('pending-admin-${u.id}'),
                  user: u,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PendingAdminCard extends ConsumerWidget {
  const _PendingAdminCard({super.key, required this.user});

  final PendingUserDto user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return MergeSemantics(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.admin_panel_settings_outlined, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name.isEmpty ? l10n.noName : user.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.phoneNumber.isEmpty ? l10n.noPhone : user.phoneNumber,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: l10n.approve,
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () async {
                      try {
                        await ref
                            .read(superAdminRepositoryProvider)
                            .approveAdmin(user.id);
                        ref.invalidate(pendingAdminsProvider);
                        if (context.mounted) {
                          cw.showSuccessSnackbar(
                            context,
                            '${l10n.approvedUser} ${user.name}.',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          cw.showErrorSnackbar(
                            context,
                            userFriendlyMessage(e, l10n),
                          );
                        }
                      }
                    },
                  ),
                  IconButton(
                    tooltip: l10n.reject,
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () async {
                      final ok = await cw.showConfirmDialog(
                        context,
                        title: l10n.rejectAdminTitle,
                        content: l10n.rejectUserConfirm(
                          user.name.isEmpty ? l10n.rejectThisUser : user.name,
                        ),
                        confirmText: l10n.reject,
                      );
                      if (!ok) return;
                      try {
                        await ref
                            .read(superAdminRepositoryProvider)
                            .rejectAdmin(user.id);
                        ref.invalidate(pendingAdminsProvider);
                        if (context.mounted) {
                          cw.showSuccessSnackbar(
                            context,
                            '${l10n.rejectedUser} ${user.name}.',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          cw.showErrorSnackbar(
                            context,
                            userFriendlyMessage(e, l10n),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
