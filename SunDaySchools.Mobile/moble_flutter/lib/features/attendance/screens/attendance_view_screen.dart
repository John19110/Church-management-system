import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_models.dart';
import '../providers/attendance_providers.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../../core/l10n/app_localizations.dart';

class AttendanceViewScreen extends ConsumerWidget {
  final int sessionId;
  const AttendanceViewScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sessionAsync = ref.watch(attendanceSessionProvider(sessionId));

    return Scaffold(
      appBar: AppBar(title: Text('${l10n.sessionId} #$sessionId')),
      body: sessionAsync.when(
        loading: () => const cw.LoadingWidget(),
        error: (e, _) => cw.AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(attendanceSessionProvider(sessionId)),
        ),
        data: (session) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.sessionInfo,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (session.createdAt != null)
                      Text('${l10n.date}: ${session.createdAt}'),
                    if (session.notes != null && session.notes!.isNotEmpty)
                      Text('${l10n.notes}: ${session.notes}'),
                    Text('${l10n.records}: ${session.records.length}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...session.records.map((record) => Card(
                  child: ListTile(
                    leading: Icon(
                      _statusIcon(record.status),
                      color: _statusColor(record.status),
                    ),
                    title: Text('Child #${record.childId}'),
                    subtitle: Text(
                      _statusLabel(
                          AttendanceStatus.fromValue(record.status), l10n),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (record.madeHomeWork)
                          const Icon(Icons.book, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        if (record.hasTools)
                          const Icon(Icons.build,
                              size: 16, color: Colors.green),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  String _statusLabel(AttendanceStatus s, AppLocalizations l10n) {
    switch (s) {
      case AttendanceStatus.present:
        return l10n.present;
      case AttendanceStatus.absent:
        return l10n.absent;
      case AttendanceStatus.late:
        return l10n.late;
      case AttendanceStatus.excused:
        return l10n.excused;
    }
  }

  IconData _statusIcon(int status) {
    switch (AttendanceStatus.fromValue(status)) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.late:
        return Icons.access_time;
      case AttendanceStatus.excused:
        return Icons.info;
    }
  }

  Color _statusColor(int status) {
    switch (AttendanceStatus.fromValue(status)) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.excused:
        return Colors.blue;
    }
  }
}
