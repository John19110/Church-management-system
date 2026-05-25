import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../../custom_field/providers/custom_field_cache_providers.dart';
import '../../unified_form/providers/unified_form_providers.dart';
import '../../unified_form/widgets/unified_entity_form.dart';
import '../models/meeting_models.dart';

class MeetingDetailScreen extends ConsumerWidget {
  final MeetingReadDto meeting;

  const MeetingDetailScreen({super.key, required this.meeting});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final appointment = meeting.weeklyAppointment ?? '-';
    final day = meeting.dayOfWeek ?? '-';
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
              icon: const Icon(Icons.edit_note),
              tooltip: l10n.editEntityFields,
              onPressed: () => context.push(
                '/custom-fields/values/Meeting/$meetingId',
              ),
            ),
          if (role == 'admin' || role == 'superadmin')
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: l10n.manageCustomFields,
              onPressed: () async {
                await context.push('/custom-fields/Meeting');
                if (context.mounted) {
                  refreshEntityFormsAfterDefinitionChange(
                    ref,
                    UnifiedEntityNames.meeting,
                  );
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoTile(label: l10n.nameLabel, value: meeting.name ?? '-'),
          _InfoTile(label: l10n.dayOfWeekLabel, value: day),
          _InfoTile(label: l10n.weeklyAppointmentLabel, value: appointment),
          _InfoTile(
            label: l10n.servantsCountLabel,
            value: meeting.servantsCount.toString(),
          ),
          _InfoTile(
            label: l10n.membersCountLabel,
            value: meeting.membersCount.toString(),
          ),
          if (formAsync != null)
            formAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (form) => UnifiedEntityDetailFields(fields: form.fields),
            ),
          const SizedBox(height: 16),
          Text(
            l10n.servants,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._buildNameList(meeting.servantNames),
          const SizedBox(height: 16),
          Text(
            l10n.membersHeading,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._buildNameList(meeting.memberNames),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.member),
            icon: const Icon(Icons.group_add),
            label: Text(l10n.addUpdateRemoveMembers),
          ),
          const SizedBox(height: 12),
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

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

List<Widget> _buildNameList(List<String> names) {
  if (names.isEmpty) return const [Text('-')];
  return names.map((name) => Text('• $name')).toList();
}
