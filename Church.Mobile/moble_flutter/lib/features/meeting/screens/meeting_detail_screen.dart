import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../../custom_field/providers/custom_field_cache_providers.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../../unified_form/providers/unified_form_providers.dart';
import '../../unified_form/utils/unified_form_field_utils.dart';
import '../../unified_form/widgets/entity_fields_empty_state.dart';
import '../../unified_form/widgets/unified_entity_detail_header.dart';
import '../../unified_form/widgets/unified_entity_form.dart';
import '../../classroom/widgets/classrooms_list_section.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../models/meeting_models.dart';
import '../utils/meeting_delete_actions.dart';

class MeetingDetailScreen extends ConsumerWidget {
  final MeetingReadDto meeting;

  const MeetingDetailScreen({super.key, required this.meeting});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final meetingId = meeting.id;
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final canEdit = AuthRoleUtils.canEditMeeting(role);
    final canManageFields = AuthRoleUtils.canManageCustomFields(role);

    if (meetingId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.meetingDetails)),
        body: Center(child: Text(l10n.missingRequiredData)),
      );
    }

    final formQuery = (
      entity: UnifiedEntityNames.meeting,
      id: meetingId,
    );
    final formAsync = ref.watch(entityFormDataProvider(formQuery));

    final appBarTitle = formAsync.maybeWhen(
      data: (form) {
        final title = unifiedDisplayTitle(
          UnifiedEntityNames.meeting,
          form.fields,
          l10n: l10n,
        );
        return title == l10n.notAvailable
            ? (meeting.name ?? l10n.meetingDetails)
            : title;
      },
      orElse: () => meeting.name ?? l10n.meetingDetails,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: l10n.editEntityFields,
              onPressed: () async {
                final saved = await context.push<bool>(
                  '/meetings/$meetingId/edit',
                );
                if (saved == true && context.mounted) {
                  ref.invalidate(entityFormDataProvider(formQuery));
                }
              },
            ),
          if (canManageFields)
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: l10n.manageCustomFields,
              onPressed: () async {
                await context.push('/custom-fields/${UnifiedEntityNames.meeting}');
                if (context.mounted) {
                  refreshEntityFormsAfterDefinitionChange(
                    ref,
                    UnifiedEntityNames.meeting,
                  );
                  ref.invalidate(entityFormDataProvider(formQuery));
                }
              },
            ),
          if (AuthRoleUtils.canDeleteMeeting(role))
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              tooltip: l10n.deleteMeeting,
              onPressed: () => confirmAndDeleteMeeting(
                context,
                ref,
                meetingId: meetingId,
                l10n: l10n,
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          formAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => cw.AppErrorWidget(message: e.toString()),
            data: (form) {
              final visible = visibleUnifiedFields(
                form.fields,
                entityName: UnifiedEntityNames.meeting,
                l10n: l10n,
              );
              if (visible.isEmpty) {
                return EntityFieldsEmptyState(
                  entityName: UnifiedEntityNames.meeting,
                  canManageDefinitions: canManageFields,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UnifiedEntityDetailHeader(
                    entityName: UnifiedEntityNames.meeting,
                    fields: form.fields,
                    eyebrow: l10n.meetingDetails,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  UnifiedEntityDetailFields(
                    entityName: UnifiedEntityNames.meeting,
                    fields: form.fields,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: '${l10n.servants} (${meeting.servantNames.length})'),
          _NameChips(names: meeting.servantNames, l10n: l10n),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
              title: '${l10n.membersHeading} (${meeting.memberNames.length})'),
          _NameChips(names: meeting.memberNames, l10n: l10n),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: l10n.classrooms),
          ClassroomsListSection(
            meetingId: meetingId,
            canAddClassroom: role == 'admin' || role == 'superadmin',
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: () => context.push(
              '/meetings/$meetingId/members',
              extra: meeting.name,
            ),
            icon: const Icon(Icons.group_add),
            label: Text(l10n.addUpdateRemoveMembers),
          ),
          if (role == 'admin' || role == 'superadmin') ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push(
                '/meetings/$meetingId/servants',
                extra: meeting.name,
              ),
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(l10n.manageServants),
            ),
          ],
        ],
      ),
    );
  }
}

/// Modern chip wrap for a list of people (servants / members).
class _NameChips extends StatelessWidget {
  final List<String> names;
  final AppLocalizations l10n;

  const _NameChips({required this.names, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (names.isEmpty) {
      return Text(
        l10n.notAvailable,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: palette.textTertiary),
      );
    }

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final name in names)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: palette.neutralSoft,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline,
                    size: 15, color: palette.textSecondary),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
