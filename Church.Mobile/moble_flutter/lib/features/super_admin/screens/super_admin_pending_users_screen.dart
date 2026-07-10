import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/select_option.dart';
import '../../../shared/widgets/app_network_avatar.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../meeting/providers/meeting_providers.dart';
import '../models/super_admin_models.dart';
import '../providers/super_admin_providers.dart';

/// Super Admin only: review users awaiting approval for this church and
/// approve (assigning a meeting where required) or reject them.
class SuperAdminPendingUsersScreen extends ConsumerStatefulWidget {
  const SuperAdminPendingUsersScreen({super.key});

  @override
  ConsumerState<SuperAdminPendingUsersScreen> createState() =>
      _SuperAdminPendingUsersScreenState();
}

class _SuperAdminPendingUsersScreenState
    extends ConsumerState<SuperAdminPendingUsersScreen> {
  /// Defer mounting a [ListView] until after the route push finishes. Mounting
  /// a new viewport in the same frame as the underlying servants ListView
  /// rebuild triggers RenderViewportBase.visitChildrenForSemantics crashes.
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
    final pendingAsync = ref.watch(pendingChurchUsersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pendingUsers)),
      body: pendingAsync.when(
        loading: () => const _StaticBodyPlaceholder(),
        error: (e, _) => cw.AppErrorWidget(
          message: userFriendlyMessage(e, l10n),
          onRetry: () => ref.invalidate(pendingChurchUsersProvider),
        ),
        data: (users) {
          if (!_listViewportReady) {
            return const _StaticBodyPlaceholder();
          }
          if (users.isEmpty) {
            return cw.EmptyWidget(
              message: l10n.noPendingUsers,
              icon: Icons.pending_actions,
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(pendingChurchUsersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              addRepaintBoundaries: true,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return _PendingUserCard(
                  key: ValueKey('pending-user-${user.id}'),
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

/// Non-animated placeholder — avoids overlapping animated spinners during route
/// transitions (Flutter 3.41 viewport semantics).
class _StaticBodyPlaceholder extends StatelessWidget {
  const _StaticBodyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.pending_actions,
        size: 40,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
      ),
    );
  }
}

class _PendingUserCard extends ConsumerStatefulWidget {
  const _PendingUserCard({
    super.key,
    required this.user,
  });

  final PendingChurchUserDto user;

  @override
  ConsumerState<_PendingUserCard> createState() => _PendingUserCardState();
}

class _PendingUserCardState extends ConsumerState<_PendingUserCard> {
  bool _isProcessing = false;

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    final l = d.toLocal();
    final mm = l.month.toString().padLeft(2, '0');
    final dd = l.day.toString().padLeft(2, '0');
    return '${l.year}-$mm-$dd';
  }

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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = widget.user;
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppNetworkAvatar(
              imageUrl: user.displayImageUrl,
              debugTag: 'pending-user-${user.id}',
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.primary,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.name.isEmpty ? l10n.noName : user.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  _line(context, l10n.requestedRoleLabel,
                      _roleLabel(l10n, user)),
                  if ((user.requestedMeetingName ?? '').isNotEmpty)
                    _line(context, l10n.requestedMeetingLabel,
                        user.requestedMeetingName!),
                  _line(
                    context,
                    l10n.phoneNumber,
                    user.phoneNumber.isEmpty
                        ? l10n.noPhone
                        : user.phoneNumber,
                  ),
                  if ((user.meetingAdminPhoneNumber ?? '').isNotEmpty)
                    _line(context, l10n.meetingAdminPhone,
                        user.meetingAdminPhoneNumber!),
                  if ((user.requestedChurchPublicId ?? '').isNotEmpty
                      && !user.registeredViaMeetingId)
                    _line(context, l10n.publicChurchIdLabel,
                        user.requestedChurchPublicId!),
                  _line(context, l10n.registrationDateLabel,
                      _formatDate(user.createdAt)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Row gives horizontal children unbounded width; ElevatedButton.icon
        // then asserts BoxConstraints(w=Infinity) inside a ListView item (line 224).
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
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
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text('$label: $value', style: style),
    );
  }

  Future<void> _approve(BuildContext context) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final l10n = AppLocalizations.of(context);
      final user = widget.user;

      if (!user.requiresMeeting) {
        await _runApprove(context, meetingId: null);
        return;
      }

      if (user.hasPrelinkedMeeting) {
        await _runApprove(context, meetingId: user.requestedMeetingId);
        return;
      }

      List<SelectOption> meetings;
      try {
        meetings = await _loadMeetingsForApproval(ref);
      } catch (e) {
        if (context.mounted) {
          cw.showErrorSnackbar(context, userFriendlyMessage(e, l10n));
        }
        return;
      }

      if (!context.mounted) return;

      if (kDebugMode) {
        debugPrint(
          '[ApproveUser] userId=${user.id} role=${user.role} '
          'requestedRole=${user.requestedRole} meetings=${meetings.length}',
        );
      }

      if (meetings.isEmpty) {
        cw.showErrorSnackbar(context, l10n.noMeetingsToAssign);
        return;
      }

      final requested =
          (user.requestedMeetingName ?? '').trim().toLowerCase();

      int? selectedMeetingId = meetings
          .where((m) => m.name.trim().toLowerCase() == requested)
          .map((m) => m.id)
          .cast<int?>()
          .firstWhere((id) => id != null, orElse: () => null);

      final approved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          int? tempSelectedId = selectedMeetingId;
          return StatefulBuilder(
            builder: (dialogContext, setState) {
              return AlertDialog(
                title: Text(l10n.approveUserTitle),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('${l10n.requestedRoleLabel}: ${user.role}'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: tempSelectedId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.selectMeeting,
                      ),
                      items: meetings
                          .map(
                            (m) => DropdownMenuItem<int>(
                              value: m.id,
                              child: Text(m.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => tempSelectedId = v),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(l10n.cancel),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (tempSelectedId == null) {
                        cw.showErrorSnackbar(
                          ctx,
                          l10n.meetingSelectionRequired,
                        );
                        selectedMeetingId = null;
                        return;
                      }
                      selectedMeetingId = tempSelectedId;
                      Navigator.of(ctx).pop(true);
                    },
                    child: Text(l10n.approve),
                  ),
                ],
              );
            },
          );
        },
      );

      if (approved != true || selectedMeetingId == null) return;
      if (!context.mounted) return;

      await _runApprove(context, meetingId: selectedMeetingId);
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        cw.showErrorSnackbar(
          context,
          userFriendlyMessage(e, l10n),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Fresh API read for the approval dialog — avoids a cached empty
  /// [meetingsForSelectionProvider] result from a pre-login fetch.
  Future<List<SelectOption>> _loadMeetingsForApproval(WidgetRef ref) async {
    ref.invalidate(meetingsForSelectionProvider);
    final repo = ref.read(meetingRepositoryProvider);

    final selectOptions = await repo.getForSelection();
    if (kDebugMode) {
      debugPrint(
        '[ApproveUser] GET /api/Meeting/select -> ${selectOptions.length} item(s)',
      );
    }
    if (selectOptions.isNotEmpty) {
      return selectOptions;
    }

    // Same church scope as the Super Admin home screen list.
    final visible = await repo.getVisibleMeetings();
    if (kDebugMode) {
      debugPrint(
        '[ApproveUser] GET /api/Meeting/visible -> ${visible.length} item(s)',
      );
    }

    return visible
        .where((m) => m.id != null && m.id! > 0)
        .map((m) => SelectOption(id: m.id!, name: m.name?.trim() ?? ''))
        .toList();
  }

  Future<void> _runApprove(
    BuildContext context, {
    required int? meetingId,
  }) async {
    final l10n = AppLocalizations.of(context);
    final user = widget.user;

    try {
      await ref
          .read(superAdminRepositoryProvider)
          .approveUser(user.id, meetingId: meetingId);

      if (mounted) {
        ref.invalidate(pendingChurchUsersProvider);
      }

      if (mounted) {
        cw.showSuccessSnackbar(
          context,
          '${l10n.approvedUser}: ${user.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        cw.showErrorSnackbar(
          context,
          userFriendlyMessage(e, l10n),
        );
      }
    }
  }

  Future<void> _reject(BuildContext context) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final l10n = AppLocalizations.of(context);
      final user = widget.user;
      final reasonController = TextEditingController();

      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            title: Text(l10n.reject),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.rejectUserConfirm(
                  user.name.isEmpty ? l10n.rejectThisUser : user.name,
                )),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: l10n.rejectReasonOptional,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.reject),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;
      if (!context.mounted) return;

      final reason = reasonController.text.trim();

      await ref.read(superAdminRepositoryProvider).rejectUser(
            user.id,
            reason: reason.isEmpty ? null : reason,
          );

      if (mounted) {
        ref.invalidate(pendingChurchUsersProvider);
      }

      if (mounted) {
        cw.showSuccessSnackbar(
          context,
          '${l10n.rejectedUser}: ${user.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        cw.showErrorSnackbar(
          context,
          userFriendlyMessage(e, l10n),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
