import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../models/classroom_models.dart';
import '../providers/classroom_providers.dart';

/// Inline classrooms list for embedding in meeting detail (no separate page).
class ClassroomsListSection extends ConsumerWidget {
  final int meetingId;
  final bool canAddClassroom;

  const ClassroomsListSection({
    super.key,
    required this.meetingId,
    required this.canAddClassroom,
  });

  Future<void> _openAddClassroom(BuildContext context, WidgetRef ref) async {
    await context.push('/classrooms/add', extra: meetingId);
    invalidateVisibleClassrooms(ref, meetingId: meetingId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final classroomsAsync =
        ref.watch(visibleClassroomsByMeetingProvider(meetingId));

    return classroomsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('${l10n.failedToLoadVisibleClassrooms} $e'),
        ),
      ),
      data: (classrooms) {
        final filtered =
            classrooms.where((c) => c.meetingId == meetingId).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (canAddClassroom) ...[
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () => _openAddClassroom(context, ref),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addClassroom),
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (filtered.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.noVisibleClassroomsFound),
                ),
              )
            else
              ...filtered.map((c) => _ClassroomCard(classroom: c)),
          ],
        );
      },
    );
  }
}

class _ClassroomCard extends StatelessWidget {
  final ClassroomReadDto classroom;

  const _ClassroomCard({required this.classroom});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.push(AppRoutes.classroomDetail, extra: classroom),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.class_,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      classroom.name ?? l10n.notAvailable,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.ageLabelText(classroom.ageOfMembers),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.membersAndSessionsLine(
                  classroom.totalMembersCount ?? 0,
                  classroom.pastAttendanceSessionsCount ?? 0,
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
