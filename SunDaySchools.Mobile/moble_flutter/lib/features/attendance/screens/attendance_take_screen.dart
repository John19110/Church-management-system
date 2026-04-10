import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/attendance_models.dart';
import '../providers/attendance_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../../member/providers/members_providers.dart';
import '../../member/models/member_models.dart';
import '../../../shared/widgets/app_section_bottom_navigation_bar.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../core/l10n/app_localizations.dart';

/// State for a single attendance record row.
class _RecordState {
  final MemberReadDto member;
  AttendanceStatus status;
  bool madeHomework;
  bool hasTools;
  String? note;

  _RecordState({
    required this.member,
    this.status = AttendanceStatus.present,
    this.madeHomework = false,
    this.hasTools = false,
    this.note,
  });
}

class AttendanceTakeScreen extends ConsumerStatefulWidget {
  final int? classroomId;
  const AttendanceTakeScreen({super.key, this.classroomId});

  @override
  ConsumerState<AttendanceTakeScreen> createState() =>
      _AttendanceTakeScreenState();
}

class _AttendanceTakeScreenState extends ConsumerState<AttendanceTakeScreen> {
  final _classroomController = TextEditingController();
  final _notesController = TextEditingController();
  List<_RecordState>? _records;
  bool _loading = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.classroomId != null) {
      _classroomController.text = widget.classroomId.toString();
    }
  }

  @override
  void dispose() {
    _classroomController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _loading = true);
    try {
      final classroomId = int.tryParse(_classroomController.text.trim());
      List<MemberReadDto> members;
      if (classroomId != null) {
        members = await ref
            .read(membersRepositoryProvider)
            .getByClassroom(classroomId);
      } else {
        members = await ref.read(membersRepositoryProvider).getAll();
      }
      setState(() {
        _records = members.map((m) => _RecordState(member: m)).toList();
      });
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_records == null || _records!.isEmpty) {
      showErrorSnackbar(context, l10n.loadMembersFirst);
      return;
    }
    final classroomId = int.tryParse(_classroomController.text.trim());
    if (classroomId == null) {
      showErrorSnackbar(context, l10n.enterClassroomId);
      return;
    }
    setState(() => _submitting = true);
    try {
      final dto = AttendanceSessionAddDto(
        classroomId: classroomId,
        notes: _notesController.text.trim().nullIfEmpty,
        records: _records!
            .map((r) => AttendanceRecordDto(
                  memberId: r.member.id,
                  madeHomeWork: r.madeHomework,
                  hasTools: r.hasTools,
                  status: r.status.value,
                  note: r.note,
                ))
            .toList(),
      );
      await ref.read(attendanceRepositoryProvider).create(dto);
      if (mounted) {
        showSuccessSnackbar(context, l10n.attendanceSaved);
        context.pop();
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(currentUserRoleProvider).valueOrNull;
    final homeRoute = AuthRoleUtils.routeForRole(role);
    final currentLocation = GoRouterState.of(context).matchedLocation;

    return PopScope(
      canPop: currentLocation == homeRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go(homeRoute);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.takeAttendance)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _classroomController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.classroomId,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 48),
                    ),
                    onPressed: _loading ? null : _loadMembers,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.load),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: l10n.sessionNotes,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_records != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${_records!.length} ${l10n.members.toLowerCase()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() {
                        for (final r in _records!) {
                          r.status = AttendanceStatus.present;
                        }
                      }),
                      child: Text(l10n.markAllPresent),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _records!.length,
                  itemBuilder: (context, index) {
                    final record = _records![index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    record.member.fullName ??
                                        'Member #${record.member.id}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                DropdownButton<AttendanceStatus>(
                                  value: record.status,
                                  isDense: true,
                                  onChanged: (v) =>
                                      setState(() => record.status = v!),
                                  items: AttendanceStatus.values
                                      .map((s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(_statusLabel(s, l10n)),
                                          ))
                                      .toList(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Checkbox(
                                  value: record.madeHomework,
                                  onChanged: (v) =>
                                      setState(() => record.madeHomework = v!),
                                ),
                                Text(l10n.homework),
                                const SizedBox(width: 16),
                                Checkbox(
                                  value: record.hasTools,
                                  onChanged: (v) =>
                                      setState(() => record.hasTools = v!),
                                ),
                                Text(l10n.tools),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else
              Expanded(
                child: Center(
                  child: Text(
                    l10n.enterClassroomAndLoad,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: _submitting
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submit,
                          child: Text(l10n.submit),
                        ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: AppSectionBottomNavigationBar(
          currentIndex: 3,
          homeRoute: homeRoute,
        ),
      ),
    );
  }
}

extension _StringExt on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
