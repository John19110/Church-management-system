import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/select_option.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/app_network_avatar.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../admin/providers/admin_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../meeting/providers/meeting_providers.dart';
import '../../super_admin/providers/super_admin_providers.dart';
import '../models/pending_request.dart';
import '../providers/pending_requests_provider.dart';

class PendingRequestCard extends ConsumerStatefulWidget {
  const PendingRequestCard({super.key, required this.request});

  final PendingRequest request;

  @override
  ConsumerState<PendingRequestCard> createState() => _PendingRequestCardState();
}

class _PendingRequestCardState extends ConsumerState<PendingRequestCard> {
  bool _isProcessing = false;

  String _roleLabel(AppLocalizations l10n) {
    switch (widget.request.roleKey.toLowerCase().replaceAll(' ', '')) {
      case 'servant':
        return l10n.registerTypeServant;
      case 'meetingadmin':
      case 'admin':
        return l10n.registerTypeMeetingAdmin;
      case 'churchadmin':
      case 'superadmin':
        return l10n.registerTypeChurchAdmin;
      default:
        return widget.request.roleKey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  bool _isAlreadyProcessed(Object error) {
    final message = userFriendlyMessage(error).toLowerCase();
    return message.contains('already approved') ||
        message.contains('cannot be rejected') ||
        message.contains('cannot be approved') ||
        message.contains('already been processed');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final request = widget.request;
    final user = request.churchUser;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppNetworkAvatar(
                  imageUrl: user?.displayImageUrl,
                  radius: 28,
                  backgroundColor: theme.colorScheme.primary,
                  placeholder: Text(
                    request.initials,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.name.isEmpty ? l10n.noName : request.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.phoneNumber.isEmpty
                            ? l10n.noPhone
                            : request.phoneNumber,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.requestedAccess,
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        _roleLabel(l10n),
                        style: theme.textTheme.titleSmall,
                      ),
                      if ((user?.requestedMeetingName ?? '').isNotEmpty)
                        Text(
                          '${l10n.requestedMeetingLabel}: ${user!.requestedMeetingName}',
                          style: theme.textTheme.bodySmall,
                        ),
                      if (request.requestedAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _formatDate(request.requestedAt),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                TextButton(
                  onPressed: _isProcessing ? null : () => _reject(context),
                  child: Text(l10n.reject),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _isProcessing ? null : () => _approve(context),
                  child: Text(l10n.approve),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context) async {
    if (_isProcessing) return;
    final l10n = AppLocalizations.of(context);
    final request = widget.request;
    final user = request.churchUser;

    final confirmed = await cw.showConfirmDialog(
      context,
      title: l10n.approveRequestTitle,
      content: l10n.approveRequestBody(request.name, _roleLabel(l10n)),
      confirmText: l10n.approve,
      confirmColor: context.palette.success,
    );
    if (!confirmed || !context.mounted) return;

    int? meetingId = user?.hasPrelinkedMeeting == true
        ? user!.requestedMeetingId
        : null;

    if (user != null &&
        user.requiresMeeting &&
        !user.hasPrelinkedMeeting &&
        request.source == PendingRequestSource.registration) {
      meetingId = await _pickMeeting(context, user.name);
      if (meetingId == null) return;
    }

    setState(() => _isProcessing = true);
    try {
      await _runApprove(meetingId: meetingId);
      if (!mounted) return;
      invalidatePendingRequests(ref);
      cw.showSuccessSnackbar(context, l10n.requestApproved);
    } catch (e) {
      if (!mounted) return;
      if (_isAlreadyProcessed(e)) {
        cw.showErrorSnackbar(context, l10n.requestAlreadyProcessed);
        invalidatePendingRequests(ref);
      } else {
        cw.showErrorSnackbar(context, l10n.requestApproveFailed);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _reject(BuildContext context) async {
    if (_isProcessing) return;
    final l10n = AppLocalizations.of(context);

    final confirmed = await cw.showConfirmDialog(
      context,
      title: l10n.rejectRequestTitle,
      content: l10n.rejectRequestBody,
      confirmText: l10n.reject,
    );
    if (!confirmed || !context.mounted) return;

    setState(() => _isProcessing = true);
    try {
      await _runReject();
      if (!mounted) return;
      invalidatePendingRequests(ref);
      cw.showSuccessSnackbar(context, l10n.requestRejected);
    } catch (e) {
      if (!mounted) return;
      if (_isAlreadyProcessed(e)) {
        cw.showErrorSnackbar(context, l10n.requestAlreadyProcessed);
        invalidatePendingRequests(ref);
      } else {
        cw.showErrorSnackbar(context, userFriendlyMessage(e, l10n));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _runApprove({int? meetingId}) async {
    final request = widget.request;
    if (request.source == PendingRequestSource.legacyAdmin) {
      await ref.read(superAdminRepositoryProvider).approveAdmin(request.id);
      return;
    }
    if (request.source == PendingRequestSource.legacyServant) {
      await ref.read(adminRepositoryProvider).approveServant(request.id);
      return;
    }
    final role = await ref.read(currentUserRoleProvider.future);
    if (role == 'superadmin') {
      await ref
          .read(superAdminRepositoryProvider)
          .approveUser(request.id, meetingId: meetingId);
      return;
    }
    await ref
        .read(adminRepositoryProvider)
        .approveUser(request.id, meetingId: meetingId);
  }

  Future<void> _runReject() async {
    final request = widget.request;
    if (request.source == PendingRequestSource.legacyAdmin) {
      await ref.read(superAdminRepositoryProvider).rejectAdmin(request.id);
      return;
    }
    if (request.source == PendingRequestSource.legacyServant) {
      await ref.read(adminRepositoryProvider).rejectServant(request.id);
      return;
    }
    final role = await ref.read(currentUserRoleProvider.future);
    if (role == 'superadmin') {
      await ref.read(superAdminRepositoryProvider).rejectUser(request.id);
      return;
    }
    await ref.read(adminRepositoryProvider).rejectUser(request.id);
  }

  Future<int?> _pickMeeting(BuildContext context, String userName) async {
    final l10n = AppLocalizations.of(context);
    List<SelectOption> meetings;
    try {
      ref.invalidate(meetingsForSelectionProvider);
      meetings = await ref.read(meetingRepositoryProvider).getForSelection();
      if (meetings.isEmpty) {
        final visible =
            await ref.read(meetingRepositoryProvider).getVisibleMeetings();
        meetings = visible
            .where((m) => m.id != null && m.id! > 0)
            .map((m) => SelectOption(id: m.id!, name: m.name?.trim() ?? ''))
            .toList();
      }
    } catch (e) {
      if (context.mounted) {
        cw.showErrorSnackbar(context, userFriendlyMessage(e, l10n));
      }
      return null;
    }

    if (!context.mounted) return null;
    if (meetings.isEmpty) {
      cw.showErrorSnackbar(context, l10n.noMeetingsToAssign);
      return null;
    }

    int? selected = meetings.length == 1 ? meetings.first.id : null;
    final approved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(l10n.approveRequestTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selected,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l10n.selectMeeting),
                    items: meetings
                        .map(
                          (m) => DropdownMenuItem<int>(
                            value: m.id,
                            child: Text(m.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialogState(() => selected = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    if (selected == null) {
                      cw.showErrorSnackbar(ctx, l10n.meetingSelectionRequired);
                      return;
                    }
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
    if (kDebugMode) {
      debugPrint('[ApproveUser] meeting=$selected approved=$approved');
    }
    return approved == true ? selected : null;
  }
}
