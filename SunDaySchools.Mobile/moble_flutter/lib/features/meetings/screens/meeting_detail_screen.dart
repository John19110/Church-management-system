import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_router.dart';
import '../models/meeting_models.dart';

class MeetingDetailScreen extends StatelessWidget {
  final MeetingReadDto meeting;

  const MeetingDetailScreen({super.key, required this.meeting});

  @override
  Widget build(BuildContext context) {
    final appointment = meeting.weeklyAppointment == null
        ? '-'
        : meeting.weeklyAppointment!.toLocal().toString();

    return Scaffold(
      appBar: AppBar(title: Text(meeting.name ?? 'Meeting Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoTile(label: 'Name', value: meeting.name ?? '-'),
          _InfoTile(label: 'Weekly appointment', value: appointment),
          _InfoTile(
            label: 'Servants count',
            value: meeting.servantsCount.toString(),
          ),
          _InfoTile(
            label: 'Members count',
            value: meeting.membersCount.toString(),
          ),
          const SizedBox(height: 16),
          Text(
            'Servants',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._buildNameList(meeting.servantNames),
          const SizedBox(height: 16),
          Text(
            'Members',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._buildNameList(meeting.memberNames),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.children),
            icon: const Icon(Icons.group_add),
            label: const Text('Add/Update/Remove Members'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.servants),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Manage Servants'),
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
