import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../auth/providers/auth_providers.dart';
import '../models/attendance_criterion_models.dart';
import '../providers/attendance_providers.dart';

/// Meeting Admin / Church Super Admin manage attendance checklist criteria.
class AttendanceCriteriaScreen extends ConsumerStatefulWidget {
  final int meetingId;
  final String? meetingName;

  const AttendanceCriteriaScreen({
    super.key,
    required this.meetingId,
    this.meetingName,
  });

  @override
  ConsumerState<AttendanceCriteriaScreen> createState() =>
      _AttendanceCriteriaScreenState();
}

class _AttendanceCriteriaScreenState
    extends ConsumerState<AttendanceCriteriaScreen> {
  Future<void> _reload() async {
    ref.invalidate(attendanceCriteriaManageProvider(widget.meetingId));
    ref.invalidate(attendanceCriteriaByMeetingProvider(widget.meetingId));
    await ref.read(attendanceCriteriaManageProvider(widget.meetingId).future);
  }

  Future<void> _showEditor({AttendanceCriterionDto? existing}) async {
    final l10n = AppLocalizations.of(context);
    final nameController =
        TextEditingController(text: existing?.displayName ?? '');
    final nameArController =
        TextEditingController(text: existing?.displayNameAr ?? '');
    var isActive = existing?.isActive ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null
                    ? l10n.addAttendanceCriterion
                    : l10n.editAttendanceCriterion,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    controller: nameController,
                    label: l10n.criterionDisplayName,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: nameArController,
                    label: l10n.criterionDisplayNameAr,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  if (existing != null)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.active),
                      value: isActive,
                      onChanged: (v) => setDialogState(() => isActive = v),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !mounted) {
      nameController.dispose();
      nameArController.dispose();
      return;
    }

    final displayName = nameController.text.trim();
    final displayNameAr = nameArController.text.trim();
    nameController.dispose();
    nameArController.dispose();

    if (displayName.isEmpty) {
      showErrorSnackbar(context, l10n.criterionDisplayNameRequired);
      return;
    }

    try {
      final repo = ref.read(attendanceCriterionRepositoryProvider);
      if (existing == null) {
        await repo.create(
          widget.meetingId,
          displayName: displayName,
          displayNameAr: displayNameAr.isEmpty ? null : displayNameAr,
        );
      } else {
        await repo.update(
          existing.id,
          displayName: displayName,
          displayNameAr: displayNameAr.isEmpty ? null : displayNameAr,
          isActive: isActive,
          sortOrder: existing.sortOrder,
        );
      }
      await _reload();
      if (mounted) {
        showSuccessSnackbar(
          context,
          existing == null
              ? l10n.criterionAddedSuccessfully
              : l10n.criterionUpdatedSuccessfully,
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, userFriendlyMessage(e, l10n));
      }
    }
  }

  Future<void> _delete(AttendanceCriterionDto criterion) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAttendanceCriterion),
        content: Text(l10n.deleteAttendanceCriterionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(attendanceCriterionRepositoryProvider)
          .softDelete(criterion.id);
      await _reload();
      if (mounted) {
        showSuccessSnackbar(context, l10n.criterionDeletedSuccessfully);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, userFriendlyMessage(e, l10n));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final canManage = role == 'admin' || role == 'superadmin';
    final criteriaAsync =
        ref.watch(attendanceCriteriaManageProvider(widget.meetingId));
    final title = widget.meetingName?.trim().isNotEmpty == true
        ? '${l10n.attendanceCriteria} — ${widget.meetingName}'
        : l10n.attendanceCriteria;

    if (!canManage) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(l10n.adminOnlyScreen)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditor(),
        child: const Icon(Icons.add),
      ),
      body: criteriaAsync.when(
        // Keep the list mounted during invalidate/reload so ReorderableListView
        // semantics/parentData are not torn down mid-frame after delete/reorder.
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const cw.LoadingWidget(useSkeleton: true),
        error: (e, _) => cw.AppErrorWidget(
          message: userFriendlyMessage(e, l10n),
          onRetry: _reload,
        ),
        data: (criteria) {
          if (criteria.isEmpty) {
            return cw.EmptyWidget(
              message: l10n.noAttendanceCriteriaYet,
              icon: Icons.checklist_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: criteria.length,
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex -= 1;
                final ordered = [...criteria];
                final item = ordered.removeAt(oldIndex);
                ordered.insert(newIndex, item);
                try {
                  await ref
                      .read(attendanceCriterionRepositoryProvider)
                      .reorder(
                        widget.meetingId,
                        ordered.map((c) => c.id).toList(),
                      );
                  await _reload();
                } catch (e) {
                  if (!context.mounted) return;
                  showErrorSnackbar(
                    context,
                    userFriendlyMessage(e, l10n),
                  );
                }
              },
              itemBuilder: (context, index) {
                final c = criteria[index];
                final label = c.labelForLocale(Localizations.localeOf(context));
                return Card(
                  key: ValueKey(c.id),
                  child: ListTile(
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                    title: Text(label),
                    subtitle: Text(
                      c.isActive ? l10n.active : l10n.inactive,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showEditor(existing: c),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () => _delete(c),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
