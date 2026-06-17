import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../providers/attendance_providers.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;

class AttendanceHistoryScreen extends ConsumerWidget {
  final int classroomId;
  final String? classroomName;

  const AttendanceHistoryScreen({
    super.key,
    required this.classroomId,
    this.classroomName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sessionsAsync =
        ref.watch(attendanceHistoryByClassroomProvider(classroomId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.attendanceHistoryTitle(classroomName)),
      ),
      body: sessionsAsync.when(
        loading: () => const cw.LoadingWidget(),
        error: (e, _) => cw.AppErrorWidget(
          message: userFriendlyMessage(e, l10n),
          onRetry: () => ref.invalidate(
            attendanceHistoryByClassroomProvider(classroomId),
          ),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return cw.EmptyWidget(
              message: l10n.noAttendanceSessionsYet,
              icon: Icons.history,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(
              attendanceHistoryByClassroomProvider(classroomId),
            ),
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
