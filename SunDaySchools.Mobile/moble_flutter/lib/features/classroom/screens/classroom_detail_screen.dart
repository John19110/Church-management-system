import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../member/providers/members_providers.dart';
import '../models/classroom_models.dart';

class ClassroomDetailScreen extends ConsumerWidget {
  final ClassroomReadDto classroom;

  const ClassroomDetailScreen({super.key, required this.classroom});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final classroomId = classroom.id;
    if (classroomId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Classroom')),
        body: const Center(
          child: Text('Invalid classroom: missing id.'),
        ),
      );
    }

    final membersAsync = ref.watch(membersByClassroomProvider(classroomId));

    return Scaffold(
      appBar: AppBar(
        title: Text(classroom.name ?? 'Classroom'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'addMember':
                  context.push('/members/add', extra: classroomId);
                  break;
                case 'members':
                  context.push(AppRoutes.member);
                  break;
                case 'servants':
                  context.push(AppRoutes.servants);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'addMember',
                child: Text(l10n.addMember),
              ),
              const PopupMenuItem(
                value: 'members',
                child: Text('Add/Update/Remove Members'),
              ),
              const PopupMenuItem(
                value: 'servants',
                child: Text('Manage Servants'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Age group: ${classroom.ageOfMembers ?? '—'}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${classroom.totalMembersCount ?? 0} members · '
                  '${classroom.pastAttendanceSessionsCount ?? 0} past attendance sessions',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                if (classroom.servantNames.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Servants: ${classroom.servantNames.join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Members',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(membersByClassroomProvider(classroomId));
                await ref.read(membersByClassroomProvider(classroomId).future);
              },
              child: membersAsync.when(
                loading: () => ListView(
                  children: const [
                    SizedBox(height: 80),
                    Center(child: CircularProgressIndicator()),
                  ],
                ),
                error: (e, _) => ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text('Could not load members: $e'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(
                        membersByClassroomProvider(classroomId),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
                data: (members) {
                  if (members.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: const [
                        Text('No members in this classroom yet.'),
                      ],
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final m = members[index];
                      final name = m.fullName?.trim().isNotEmpty == true
                          ? m.fullName!
                          : 'Member #${m.id}';
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => context.push('/member/${m.id}'),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  backgroundImage: m.imageUrl != null &&
                                          m.imageUrl!.isNotEmpty
                                      ? NetworkImage(m.imageUrl!)
                                      : null,
                                  child: m.imageUrl == null ||
                                          m.imageUrl!.isEmpty
                                      ? Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : '?',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: () => context.push(
                    '${AppRoutes.attendanceTake}?classroomId=$classroomId',
                  ),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text(l10n.takeAttendance),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => context.push(
                    '${AppRoutes.attendanceHistory}/$classroomId?classroomName=${Uri.encodeComponent(classroom.name ?? '')}',
                  ),
                  icon: const Icon(Icons.history),
                  label: const Text('Attendance history'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
