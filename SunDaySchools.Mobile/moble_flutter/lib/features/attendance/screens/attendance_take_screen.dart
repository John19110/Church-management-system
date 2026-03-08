import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/attendance_models.dart';
import '../providers/attendance_providers.dart';
import '../../children/providers/children_providers.dart';
import '../../children/models/child_models.dart';
import '../../../shared/widgets/common_widgets.dart';

/// State for a single attendance record row.
class _RecordState {
  final ChildReadDto child;
  AttendanceStatus status;
  bool madeHomework;
  bool hasTools;
  String? note;

  _RecordState({
    required this.child,
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

  Future<void> _loadChildren() async {
    setState(() => _loading = true);
    try {
      final classroomId = int.tryParse(_classroomController.text.trim());
      List<ChildReadDto> children;
      if (classroomId != null) {
        children = await ref
            .read(childrenRepositoryProvider)
            .getByClassroom(classroomId);
      } else {
        children = await ref.read(childrenRepositoryProvider).getAll();
      }
      setState(() {
        _records = children.map((c) => _RecordState(child: c)).toList();
      });
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_records == null || _records!.isEmpty) {
      showErrorSnackbar(context, 'Load children first');
      return;
    }
    final classroomId = int.tryParse(_classroomController.text.trim());
    if (classroomId == null) {
      showErrorSnackbar(context, 'Enter a classroom ID');
      return;
    }
    setState(() => _submitting = true);
    try {
      final dto = AttendanceSessionAddDto(
        classroomId: classroomId,
        notes: _notesController.text.trim().nullIfEmpty,
        records: _records!
            .map((r) => AttendanceRecordDto(
                  childId: r.child.id,
                  madeHomeWork: r.madeHomework,
                  hasTools: r.hasTools,
                  status: r.status.value,
                  note: r.note,
                ))
            .toList(),
      );
      await ref.read(attendanceRepositoryProvider).create(dto);
      if (mounted) {
        showSuccessSnackbar(context, 'Attendance saved!');
        context.pop();
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take Attendance')),
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
                    decoration: const InputDecoration(
                      labelText: 'Classroom ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 48),
                  ),
                  onPressed: _loading ? null : _loadChildren,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Load'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Session Notes (optional)',
                border: OutlineInputBorder(),
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
                    '${_records!.length} children',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      for (final r in _records!) {
                        r.status = AttendanceStatus.present;
                      }
                    }),
                    child: const Text('Mark All Present'),
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
                                  record.child.fullName ?? 'Child #${record.child.id}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              DropdownButton<AttendanceStatus>(
                                value: record.status,
                                isDense: true,
                                onChanged: (v) => setState(
                                    () => record.status = v!),
                                items: AttendanceStatus.values
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s.label),
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
                              const Text('Homework'),
                              const SizedBox(width: 16),
                              Checkbox(
                                value: record.hasTools,
                                onChanged: (v) =>
                                    setState(() => record.hasTools = v!),
                              ),
                              const Text('Tools'),
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
            const Expanded(
              child: Center(
                child: Text(
                  'Enter a classroom ID and tap Load\nto see children.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: _submitting
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: _submit,
                child: const Text('Save Attendance'),
              ),
      ),
    );
  }
}

extension _StringExt on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
