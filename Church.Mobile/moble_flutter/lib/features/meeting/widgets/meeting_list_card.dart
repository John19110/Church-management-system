import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../models/meeting_models.dart';

enum _MeetingCardAction { edit, delete }

/// Compact meeting row for list screens. Actions live in a ⋮ menu when allowed.
class MeetingListCard extends StatelessWidget {
  const MeetingListCard({
    super.key,
    required this.meeting,
    required this.canEdit,
    required this.canDelete,
    required this.onOpen,
    this.onEdit,
    this.onDelete,
  });

  final MeetingReadDto meeting;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  bool get _hasMenu => canEdit || canDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final name = meeting.name?.trim().isNotEmpty == true
        ? meeting.name!.trim()
        : l10n.notAvailable;
    final summary = l10n.meetingServantsMembersSummary(
      meeting.servantsCount,
      meeting.membersCount,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 0, 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            summary,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_hasMenu)
            _MeetingActionsMenu(
              canEdit: canEdit,
              canDelete: canDelete,
              onEdit: onEdit,
              onDelete: onDelete,
            )
          else
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _MeetingActionsMenu extends StatelessWidget {
  const _MeetingActionsMenu({
    required this.canEdit,
    required this.canDelete,
    this.onEdit,
    this.onDelete,
  });

  final bool canEdit;
  final bool canDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopupMenuButton<_MeetingCardAction>(
      icon: const Icon(Icons.more_vert),
      tooltip: l10n.meetingMoreActions,
      padding: EdgeInsets.zero,
      offset: const Offset(0, 40),
      onSelected: (action) {
        switch (action) {
          case _MeetingCardAction.edit:
            onEdit?.call();
          case _MeetingCardAction.delete:
            onDelete?.call();
        }
      },
      itemBuilder: (context) => [
        if (canEdit)
          PopupMenuItem(
            value: _MeetingCardAction.edit,
            child: _MenuRow(
              icon: Icons.edit_outlined,
              label: l10n.editMeeting,
            ),
          ),
        if (canDelete)
          PopupMenuItem(
            value: _MeetingCardAction.delete,
            child: _MenuRow(
              icon: Icons.delete_outline,
              label: l10n.deleteMeeting,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: color != null ? textStyle?.copyWith(color: color) : textStyle,
          ),
        ),
      ],
    );
  }
}
