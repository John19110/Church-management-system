import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../classroom/providers/classroom_providers.dart';
import '../providers/meeting_providers.dart';

Future<void> confirmAndDeleteMeeting(
  BuildContext context,
  WidgetRef ref, {
  required int meetingId,
  required AppLocalizations l10n,
  VoidCallback? onDeleted,
}) async {
  final confirmed = await cw.showConfirmDialog(
    context,
    title: l10n.deleteMeeting,
    content: l10n.confirmDeleteMeeting,
  );
  if (!confirmed) return;

  try {
    await ref.read(meetingRepositoryProvider).delete(meetingId);
    if (!context.mounted) return;
    ref.invalidate(visibleMeetingsProvider);
    invalidateVisibleClassrooms(ref, meetingId: meetingId);
    cw.showSuccessSnackbar(context, l10n.meetingDeletedSuccessfully);
    if (onDeleted != null) {
      onDeleted();
    } else if (context.canPop()) {
      context.pop();
    }
  } catch (e) {
    if (context.mounted) {
      cw.showErrorSnackbar(context, userFriendlyMessage(e, l10n));
    }
  }
}
