import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../providers/attendance_providers.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;

class AttendanceHistoryScreen extends ConsumerWidget {
  final int? classroomId;
  final String? classroomName;
  final int? meetingId;
  final String? meetingName;

  const AttendanceHistoryScreen({
    super.key,
    this.classroomId,
    this.classroomName,
    this.meetingId,
    this.meetingName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isMeetingScoped = meetingId != null && meetingId! > 0;
    final sessionsAsync = isMeetingScoped
        ? ref.watch(attendanceHistoryByMeetingProvider(meetingId!))
        : ref.watch(attendanceHistoryByClassroomProvider(classroomId!));

    final title = isMeetingScoped
        ? l10n.attendanceHistoryTitle(meetingName)
        : l10n.attendanceHistoryTitle(classroomName);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: sessionsAsync.when(
        loading: () => const cw.LoadingWidget(useSkeleton: true),
        error: (e, _) => cw.AppErrorWidget(
          message: userFriendlyMessage(e, l10n),
          onRetry: () {
            if (isMeetingScoped) {
              ref.invalidate(attendanceHistoryByMeetingProvider(meetingId!));
            } else {
              ref.invalidate(
                attendanceHistoryByClassroomProvider(classroomId!),
              );
            }
          },
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return cw.EmptyWidget(
              message: l10n.noAttendanceSessionsYet,
              icon: Icons.history,
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              if (isMeetingScoped) {
                ref.invalidate(attendanceHistoryByMeetingProvider(meetingId!));
              } else {
                ref.invalidate(
                  attendanceHistoryByClassroomProvider(classroomId!),
                );
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final s = sessions[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.event_note_outlined),
                    title: Text(
                      s.createdAt ?? l10n.sessionNumberLabel(s.id),
                    ),
                    subtitle: Text(
                      (s.notes?.trim().isNotEmpty == true)
                          ? s.notes!.trim()
                          : l10n.recordsCountLabel(s.recordsCount),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/attendance/${s.id}'),
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
