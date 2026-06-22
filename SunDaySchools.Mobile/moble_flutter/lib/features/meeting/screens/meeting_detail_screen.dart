import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
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
              icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                  ),
                  const SizedBox(height: 16),
                  UnifiedEntityDetailFields(
                    entityName: UnifiedEntityNames.meeting,
                    fields: form.fields,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            l10n.servants,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._buildNameList(meeting.servantNames, l10n),
          const SizedBox(height: 16),
          Text(
            l10n.membersHeading,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._buildNameList(meeting.memberNames, l10n),
          const SizedBox(height: 24),
          Text(
            l10n.classrooms,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ClassroomsListSection(
            meetingId: meetingId,
            canAddClassroom: role == 'admin' || role == 'superadmin',
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.member),
            icon: const Icon(Icons.group_add),
            label: Text(l10n.addUpdateRemoveMembers),
          ),
          if (role == 'admin' || role == 'superadmin') ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.servants),
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(l10n.manageServants),
            ),
          ],
        ],
      ),
    );
  }
}

List<Widget> _buildNameList(List<String> names, AppLocalizations l10n) {
  if (names.isEmpty) return [Text(l10n.notAvailable)];
  return names.map((name) => Text('• $name')).toList();
}
