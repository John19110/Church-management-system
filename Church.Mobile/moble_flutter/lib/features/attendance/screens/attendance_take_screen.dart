import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/attendance_models.dart';
import '../models/attendance_criterion_models.dart';
import '../providers/attendance_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../../classroom/providers/classroom_providers.dart';
import '../../member/providers/members_providers.dart';
import '../../member/models/member_models.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/app_section_bottom_navigation_bar.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/endpoint_select_fields.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';

/// State for a single attendance record row.
class _RecordState {
  final MemberReadDto member;
  AttendanceStatus status;
  final Map<int, bool> criterionValues;
  String? note;

  _RecordState({
    required this.member,
    this.status = AttendanceStatus.present,
    Map<int, bool>? criterionValues,
    this.note,
  }) : criterionValues = criterionValues ?? {};
}

class AttendanceTakeScreen extends ConsumerStatefulWidget {
  final int? classroomId;
  final int? meetingId;
  const AttendanceTakeScreen({
    super.key,
    this.classroomId,
    this.meetingId,
  });

  @override
  ConsumerState<AttendanceTakeScreen> createState() =>
      _AttendanceTakeScreenState();
}

class _AttendanceTakeScreenState extends ConsumerState<AttendanceTakeScreen> {
  int? _selectedClassroomId;
  int? _meetingId;
  final _notesController = TextEditingController();
  List<_RecordState>? _records;
  List<AttendanceCriterionDto> _criteria = const [];
  bool _loading = false;
  bool _submitting = false;

  bool get _isMeetingScoped =>
      _meetingId != null && _meetingId! > 0 && widget.classroomId == null;

  @override
  void initState() {
    super.initState();
    _meetingId = widget.meetingId;
    if (widget.classroomId != null) {
      _selectedClassroomId = widget.classroomId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadMembers();
      });
    } else if (_isMeetingScoped) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadMembers();
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<int?> _resolveMeetingIdForCriteria() async {
    if (_meetingId != null && _meetingId! > 0) return _meetingId;
    final classroomId = _selectedClassroomId;
    if (classroomId == null) return null;
    try {
      final classrooms = await ref.read(visibleClassroomsProvider.future);
      for (final c in classrooms) {
        if (c.id == classroomId && c.meetingId != null && c.meetingId! > 0) {
          return c.meetingId;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _loadMembers() async {
    setState(() => _loading = true);
    try {
      final classroomId = _selectedClassroomId;
      var meetingId = _meetingId;
      meetingId ??= await _resolveMeetingIdForCriteria();
      if (meetingId != null) _meetingId = meetingId;

      List<MemberReadDto> members;
      if (classroomId != null) {
        members = await ref
            .read(membersRepositoryProvider)
            .getByClassroom(classroomId);
      } else if (meetingId != null && meetingId > 0) {
        members = await ref
            .read(membersRepositoryProvider)
            .getByMeeting(meetingId);
      } else {
        members = await ref.read(membersRepositoryProvider).getAll();
      }

      List<AttendanceCriterionDto> criteria = const [];
      if (meetingId != null && meetingId > 0) {
        criteria = await ref
            .read(attendanceCriterionRepositoryProvider)
            .getByMeeting(meetingId);
      }

      setState(() {
        _criteria = criteria;
        _records = members
            .map(
              (m) => _RecordState(
                member: m,
                criterionValues: {
                  for (final c in criteria) c.id: false,
                },
              ),
            )
            .toList();
      });
    } catch (e) {
      if (mounted) {
        showErrorSnackbarFixed(
          context,
          userFriendlyMessage(e, AppLocalizations.of(context)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_records == null || _records!.isEmpty) {
      showErrorSnackbarFixed(context, l10n.loadMembersFirst);
      return;
    }
    final classroomId = _selectedClassroomId;
    final meetingId = _meetingId;
    if (classroomId == null && (meetingId == null || meetingId <= 0)) {
      showErrorSnackbarFixed(context, l10n.enterClassroomId);
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final dto = AttendanceSessionAddDto(
        classroomId: classroomId,
        meetingId: classroomId == null ? meetingId : null,
        notes: _notesController.text.trim().nullIfEmpty,
        records: _records!.map((r) {
          final results = _criteria
              .map(
                (c) => AttendanceCriterionResultDto(
                  criterionId: c.id,
                  displayName: c.displayName,
                  displayNameAr: c.displayNameAr,
                  name: c.name,
                  value: r.criterionValues[c.id] ?? false,
                ),
              )
              .toList();
          final hasTools = results
              .where((x) => x.name == 'has_tools')
              .map((x) => x.value ?? false)
              .cast<bool>()
              .followedBy(const [false])
              .first;
          final homework = results
              .where((x) => x.name == 'did_homework')
              .map((x) => x.value ?? false)
              .cast<bool>()
              .followedBy(const [false])
              .first;
          return AttendanceRecordDto(
            memberId: r.member.id,
            madeHomeWork: homework,
            hasTools: hasTools,
            status: r.status.value,
            note: r.note,
            criterionResults: results,
          );
        }).toList(),
      );
      await ref.read(attendanceRepositoryProvider).create(dto);
      if (mounted) {
        showSuccessSnackbarFixed(context, l10n.attendanceSaved);
        context.pop();
      }
    } catch (e) {
      if (mounted) showErrorSnackbarFixed(context, userFriendlyMessage(e, l10n));
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
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final homeRoute = AuthRoleUtils.routeForRole(role);
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

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
              padding: const EdgeInsets.all(AppSpacing.page),
              child: Row(
                children: [
                  if (!_isMeetingScoped)
                    Expanded(
                      child: EndpointSelectDropdown(
                        endpoint: SelectionEndpoints.classrooms,
                        label: l10n.classroomId,
                        hintText: l10n.classroomId,
                        value: _selectedClassroomId,
                        onChanged: (v) =>
                            setState(() => _selectedClassroomId = v),
                      ),
                    )
                  else
                    Expanded(
                      child: Text(
                        l10n.meetingAttendance,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  if (!_isMeetingScoped) ...[
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(88, 48),
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: AppTextField(
                controller: _notesController,
                label: l10n.sessionNotes,
                maxLines: 2,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (_loading)
              const Expanded(child: LoadingWidget(useSkeleton: true))
            else if (_records == null)
              Expanded(
                child: EmptyWidget(
                  message: _isMeetingScoped
                      ? l10n.noMembersInMeetingYet
                      : l10n.enterClassroomAndLoad,
                  icon: Icons.search,
                ),
              )
            else if (_records!.isEmpty)
              Expanded(
                child: EmptyWidget(
                  message: _isMeetingScoped
                      ? l10n.noMembersInMeetingYet
                      : l10n.noMembersInClassroomYet,
                  icon: Icons.people_outline,
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                  vertical: AppSpacing.xxs,
                ),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${l10n.formatInteger(_records!.length)} ${l10n.members.toLowerCase()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
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
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    bottom: AppSpacing.md + keyboardInset,
                  ),
                  itemCount: _records!.length,
                  itemBuilder: (context, index) {
                    final record = _records![index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.page,
                        vertical: AppSpacing.xxs,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    record.member.fullName ??
                                        l10n.memberNumberLabel(
                                          record.member.id,
                                        ),
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
                            const SizedBox(height: AppSpacing.xxs),
                            Wrap(
                              spacing: AppSpacing.md,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                for (final c in _criteria)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value:
                                            record.criterionValues[c.id] ??
                                            false,
                                        onChanged: (v) => setState(
                                          () => record.criterionValues[c.id] =
                                              v ?? false,
                                        ),
                                      ),
                                      Text(
                                        c.labelForLocale(
                                          Localizations.localeOf(context),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.xs,
                  AppSpacing.page,
                  AppSpacing.xs + keyboardInset,
                ),
                child: AppButton(
                  label: l10n.submit,
                  loading: _submitting,
                  onPressed: _submitting ? null : _submit,
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
