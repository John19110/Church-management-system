import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/app_network_avatar.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../super_admin/models/super_admin_models.dart';
import '../providers/admin_providers.dart';

/// Meeting Admin: review users who registered with this meeting's public ID.
class AdminPendingUsersScreen extends ConsumerStatefulWidget {
  const AdminPendingUsersScreen({super.key});

  @override
  ConsumerState<AdminPendingUsersScreen> createState() =>
      _AdminPendingUsersScreenState();
}

class _AdminPendingUsersScreenState
    extends ConsumerState<AdminPendingUsersScreen> {
  bool _listViewportReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _listViewportReady = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pendingAsync = ref.watch(adminPendingChurchUsersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pendingUsers)),
      body: pendingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => cw.AppErrorWidget(
          message: userFriendlyMessage(e, l10n),
          onRetry: () => ref.invalidate(adminPendingChurchUsersProvider),
        ),
        data: (users) {
          if (!_listViewportReady) {
            return const SizedBox.shrink();
          }
          if (users.isEmpty) {
            return cw.EmptyWidget(
              message: l10n.noPendingUsers,
              icon: Icons.pending_actions,
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(adminPendingChurchUsersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return _AdminPendingUserCard(
                  key: ValueKey('admin-pending-user-${user.id}'),
                  user: user,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AdminPendingUserCard extends ConsumerStatefulWidget {
  const _AdminPendingUserCard({
    super.key,
    required this.user,
  });

  final PendingChurchUserDto user;

  @override
  ConsumerState<_AdminPendingUserCard> createState() =>
      _AdminPendingUserCardState();
}

class _AdminPendingUserCardState extends ConsumerState<_AdminPendingUserCard> {
  bool _isProcessing = false;

  String _roleLabel(AppLocalizations l10n, PendingChurchUserDto user) {
    final rr = (user.requestedRole ?? user.role).toLowerCase();
    switch (rr) {
      case 'servant':
        return l10n.registerTypeServant;
      case 'meetingadmin':
      case 'admin':
        return l10n.registerTypeMeetingAdmin;
      case 'churchadmin':
      case 'superadmin':
        return l10n.registerTypeChurchAdmin;
      default:
        return user.requestedRole ?? user.role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = widget.user;
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppNetworkAvatar(
                  imageUrl: user.displayImageUrl,
                  debugTag: 'admin-pending-${user.id}',
                  radius: 28,
                  backgroundColor: const Color(0xFFED8936),
                  placeholder: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
                        '${l10n.requestedRoleLabel}: ${_roleLabel(l10n, user)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if ((user.requestedMeetingName ?? '').isNotEmpty)
                        Text(
                          '${l10n.requestedMeetingLabel}: ${user.requestedMeetingName}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      Text(
                        '${l10n.phoneNumber}: ${user.phoneNumber.isEmpty ? l10n.noPhone : user.phoneNumber}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: Text(l10n.reject),
                    onPressed: _isProcessing ? null : () => _reject(context),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: Text(l10n.approve),
                    onPressed: _isProcessing ? null : () => _approve(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    final l10n = AppLocalizations.of(context);
    final user = widget.user;

    try {
      final meetingId = user.hasPrelinkedMeeting
          ? user.requestedMeetingId
          : null;

      await ref.read(adminRepositoryProvider).approveUser(
            user.id,
            meetingId: meetingId,
          );
      ref.invalidate(adminPendingChurchUsersProvider);
      if (mounted) {
        cw.showSuccessSnackbar(
          context,
          '${l10n.approvedUser}: ${user.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        cw.showErrorSnackbar(context, userFriendlyMessage(e, l10n));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _reject(BuildContext context) async {
    if (_isProcessing) return;
    final l10n = AppLocalizations.of(context);
    final user = widget.user;

    final ok = await cw.showConfirmDialog(
      context,
      title: l10n.rejectServantTitle,
      content: l10n.rejectUserConfirm(
        user.name.isEmpty ? l10n.rejectThisUser : user.name,
      ),
      confirmText: l10n.reject,
    );
    if (!ok) return;

    setState(() => _isProcessing = true);
    try {
      await ref.read(adminRepositoryProvider).rejectUser(user.id);
      ref.invalidate(adminPendingChurchUsersProvider);
      if (mounted) {
        cw.showSuccessSnackbar(
          context,
          '${l10n.rejectedUser} ${user.name}.',
        );
      }
    } catch (e) {
      if (mounted) {
        cw.showErrorSnackbar(context, userFriendlyMessage(e, l10n));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
