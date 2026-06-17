import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../custom_field/providers/custom_field_cache_providers.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../../unified_form/providers/unified_form_providers.dart';
import '../../unified_form/widgets/unified_entity_detail_header.dart';
import '../../unified_form/widgets/unified_entity_form.dart';
import '../models/meeting_models.dart';

class MeetingDetailScreen extends ConsumerWidget {
  final MeetingReadDto meeting;

  const MeetingDetailScreen({super.key, required this.meeting});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final meetingId = meeting.id;
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final formAsync = meetingId != null
        ? ref.watch(
            entityFormDataProvider((entity: UnifiedEntityNames.meeting, id: meetingId)),
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(meeting.name ?? l10n.meetingDetails),
        actions: [
          if (meetingId != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: l10n.saveLabel,
              onPressed: () async {
                final saved = await context.push<bool>(
                  '/meetings/$meetingId/edit',
                );
                if (saved == true && context.mounted) {
                  ref.invalidate(
                    entityFormDataProvider((
                      entity: UnifiedEntityNames.meeting,
                      id: meetingId,
                    )),
                  );
                }
              },
            ),
          if (meetingId != null)
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
                  ref.invalidate(
                    entityFormDataProvider((
                      entity: UnifiedEntityNames.meeting,
                      id: meetingId,
                    )),
                  );
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (formAsync != null)
            formAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
              data: (form) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UnifiedEntityDetailHeader(
                    entityName: UnifiedEntityNames.meeting,
                    fields: form.fields,
                  ),
                  const SizedBox(height: 16),
                  UnifiedEntityDetailFields(fields: form.fields),
                  const SizedBox(height: 16),
                ],
              ),
            ),
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
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.member),
            icon: const Icon(Icons.group_add),
            label: Text(l10n.addUpdateRemoveMembers),
          ),
          const SizedBox(height: 12),
          if (role == 'admin' || role == 'superadmin')
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.servants),
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(l10n.manageServants),
            ),
        ],
      ),
    );
  }
}

List<Widget> _buildNameList(List<String> names, AppLocalizations l10n) {
  if (names.isEmpty) return [Text(l10n.notAvailable)];
  return names.map((name) => Text('• $name')).toList();
}
