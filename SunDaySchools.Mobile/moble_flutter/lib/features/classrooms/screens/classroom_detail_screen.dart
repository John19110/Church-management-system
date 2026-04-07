import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_router.dart';
import '../models/classroom_models.dart';

class ClassroomDetailScreen extends StatelessWidget {
  final ClassroomReadDto classroom;

  const ClassroomDetailScreen({super.key, required this.classroom});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(classroom.name ?? 'Classroom Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoTile(label: 'Name', value: classroom.name ?? '-'),
          _InfoTile(label: 'Age', value: classroom.ageOfMembers ?? '-'),
          _InfoTile(
            label: 'Members count',
            value: (classroom.totalMembersCount ?? 0).toString(),
          ),
          _InfoTile(
            label: 'Discipline members',
            value: (classroom.numberOfDisciplineMembers ?? 0).toString(),
          ),
          const SizedBox(height: 16),
          Text(
            'Servants',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._buildNameList(classroom.servantNames),
          const SizedBox(height: 16),
          Text(
            'Members',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._buildNameList(classroom.memberNames),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/members/add', extra: classroom.id),
            icon: const Icon(Icons.person_add),
            label: const Text('Add Member'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.members),
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
