import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../auth/utils/auth_session.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../meeting/models/meeting_models.dart';
import '../../meeting/providers/meeting_providers.dart';
import '../../../shared/widgets/app_section_bottom_navigation_bar.dart';
import '../providers/super_admin_providers.dart';
import '../../classroom/models/classroom_models.dart';
import '../../classroom/providers/classroom_providers.dart';
import '../../../shared/widgets/endpoint_select_fields.dart';

class SuperAdminHomeScreen extends ConsumerStatefulWidget {
  const SuperAdminHomeScreen({super.key});

  @override
  ConsumerState<SuperAdminHomeScreen> createState() =>
      _SuperAdminHomeScreenState();
}

class _SuperAdminHomeScreenState extends ConsumerState<SuperAdminHomeScreen> {
  final _meetingFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _timeController = TextEditingController();

  TimeOfDay? _selectedTime;
  String _selectedDay = 'Saturday';

  final _classroomFormKey = GlobalKey<FormState>();
  final _classroomNameController = TextEditingController();
  final _classroomAgeController = TextEditingController();
  int? _selectedMeetingIdForClassroom;

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    _classroomNameController.dispose();
    _classroomAgeController.dispose();
    super.dispose();
  }

  void _resetMeetingDialogState() {
    _nameController.clear();
    _timeController.clear();
    _selectedTime = null;
    _selectedDay = 'Saturday';
  }

  Future<void> _refresh() async {
    ref.invalidate(visibleMeetingsProvider);
    ref.invalidate(pendingAdminsProvider);
    await ref.read(visibleMeetingsProvider.future);
    await ref.read(pendingAdminsProvider.future);
  }

  Future<void> _createMeeting() async {
    final weekly = _selectedTime;
    if (weekly == null) {
      throw FormatException(
        AppLocalizations.of(context).weeklyAppointmentTimeRequired,
      );
    }

    await ref.read(superAdminRepositoryProvider).createMeeting(
          MeetingAddDto(
            name: _nameController.text.trim(),
            weeklyAppointment: weekly,
            dayOfWeek: _selectedDay,
          ),
        );

    ref.invalidate(visibleMeetingsProvider);
  }

  Future<void> _showAddMeetingDialog() async {
    _resetMeetingDialogState();

    var isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogBuilderContext, setDialogState) {
            final l10n = AppLocalizations.of(dialogBuilderContext);
            return AlertDialog(
              title: Text(l10n.addMeeting),
              content: SingleChildScrollView(
                child: Form(
                  key: _meetingFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n.meetingNameLabel,
                          hintText: l10n.enterMeetingNameHint,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.meetingNameRequiredGeneric;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedDay,
                        decoration: InputDecoration(
                          labelText: l10n.meetingDayOfWeek,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'Saturday',
                            child: Text(l10n.weekdaySaturday),
                          ),
                          DropdownMenuItem(
                            value: 'Sunday',
                            child: Text(l10n.weekdaySunday),
                          ),
                          DropdownMenuItem(
                            value: 'Monday',
                            child: Text(l10n.weekdayMonday),
                          ),
                          DropdownMenuItem(
                            value: 'Tuesday',
                            child: Text(l10n.weekdayTuesday),
                          ),
                          DropdownMenuItem(
                            value: 'Wednesday',
                            child: Text(l10n.weekdayWednesday),
                          ),
                          DropdownMenuItem(
                            value: 'Thursday',
                            child: Text(l10n.weekdayThursday),
                          ),
                          DropdownMenuItem(
                            value: 'Friday',
                            child: Text(l10n.weekdayFriday),
                          ),
                        ],
                        onChanged: isSubmitting
                            ? null
                            : (v) {
                                if (v == null) return;
                                if (!dialogBuilderContext.mounted) return;
                                setDialogState(() => _selectedDay = v);
                              },
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.dayOfWeekRequired
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _timeController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: l10n.weeklyAppointmentTime,
                          hintText: 'HH:mm',
                        ),
                        onTap: isSubmitting
                            ? null
                            : () async {
                                final picked = await showTimePicker(
                                  context: dialogBuilderContext,
                                  initialTime: _selectedTime ?? TimeOfDay.now(),
                                );
                                if (!dialogBuilderContext.mounted) return;
                                if (picked == null) return;
                                setDialogState(() {
                                  _selectedTime = picked;
                                  _timeController.text =
                                      picked.format(dialogBuilderContext);
                                });
                              },
                        validator: (_) => _selectedTime == null
                            ? l10n.weeklyAppointmentTimeRequired
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!_meetingFormKey.currentState!.validate()) return;
                          if (!dialogBuilderContext.mounted) return;
                          setDialogState(() => isSubmitting = true);
                          try {
                            await _createMeeting();
                            if (!mounted || !dialogBuilderContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            showSuccessSnackbar(
                              context,
                              l10n.meetingAddedSuccessfully,
                            );
                          } catch (e) {
                            if (!mounted) return;
                            showErrorSnackbar(context, e.toString());
                          } finally {
                            if (dialogBuilderContext.mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.add),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _resetAddClassroomDialogState() {
    _classroomNameController.clear();
    _classroomAgeController.clear();
    _selectedMeetingIdForClassroom = null;
  }

  Future<void> _createClassroom() async {
    await ref.read(classroomRepositoryProvider).add(
          ClassroomAddDto(
            name: _classroomNameController.text.trim(),
            ageOfMembers: _classroomAgeController.text.trim(),
            meetingId: _selectedMeetingIdForClassroom,
          ),
        );
    ref.invalidate(visibleClassroomsProvider);
  }

  Future<void> _showAddClassroomDialog() async {
    _resetAddClassroomDialogState();
    var isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogBuilderContext, setDialogState) {
            final l10n = AppLocalizations.of(dialogBuilderContext);
            return AlertDialog(
              title: Text(l10n.addClassroom),
              content: SingleChildScrollView(
                child: Form(
                  key: _classroomFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _classroomNameController,
                        decoration: InputDecoration(
                          labelText: l10n.classroomNameLabel,
                          hintText: l10n.enterClassroomNameHint,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.classroomNameRequiredGeneric;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _classroomAgeController,
                        decoration: InputDecoration(
                          labelText: l10n.ageOfMembersLabel,
                          hintText: l10n.enterAgeRangeHint,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.ageOfMembersRequiredGeneric;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      EndpointSelectDropdown(
                        endpoint: SelectionEndpoints.meetings,
                        label: '${l10n.meetingLabel} (${l10n.optional})',
                        hintText: l10n.selectMeeting,
                        value: _selectedMeetingIdForClassroom,
                        enabled: !isSubmitting,
                        onChanged: (v) => setDialogState(
                            () => _selectedMeetingIdForClassroom = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!_classroomFormKey.currentState!.validate()) {
                            return;
                          }
                          if (!dialogBuilderContext.mounted) return;
                          setDialogState(() => isSubmitting = true);
                          try {
                            await _createClassroom();
                            if (!mounted || !dialogBuilderContext.mounted) {
                              return;
                            }
                            Navigator.of(dialogContext).pop();
                            showSuccessSnackbar(
                              context,
                              l10n.classroomAddedSuccessfully,
                            );
                          } catch (e) {
                            if (!mounted) return;
                            showErrorSnackbar(context, e.toString());
                          } finally {
                            if (dialogBuilderContext.mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.add),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditMeetingDialog(MeetingReadDto meeting) async {
    final meetingId = meeting.id;
    if (meetingId == null || meetingId <= 0) {
      showErrorSnackbar(context, 'Meeting id is missing.');
      return;
    }

    var isSubmitting = false;
    int? selectedLeaderId = meeting.leaderServantId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogBuilderContext, setDialogState) {
            final l10n = AppLocalizations.of(dialogBuilderContext);
            return AlertDialog(
              title: Text(
                l10n.editMeetingTitle.replaceAll(
                  '{meeting}',
                  (meeting.name ?? meetingId.toString()),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EndpointSelectDropdown(
                      endpoint: SelectionEndpoints.servants,
                      label: l10n.leaderServantOptional,
                      hintText: l10n.selectServant,
                      value: selectedLeaderId,
                      enabled: !isSubmitting,
                      onChanged: (v) =>
                          setDialogState(() => selectedLeaderId = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!dialogBuilderContext.mounted) return;
                          setDialogState(() => isSubmitting = true);
                          try {
                            await ref
                                .read(meetingRepositoryProvider)
                                .update(meetingId, leaderServantId: selectedLeaderId);
                            ref.invalidate(visibleMeetingsProvider);
                            if (!mounted || !dialogBuilderContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            showSuccessSnackbar(context, l10n.meetingUpdated);
                          } catch (e) {
                            if (!mounted) return;
                            showErrorSnackbar(context, e.toString());
                          } finally {
                            if (dialogBuilderContext.mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.saveLabel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final meetingsAsync = ref.watch(visibleMeetingsProvider);
    final pendingAdminsAsync = ref.watch(pendingAdminsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.superAdminHome),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.addMeeting,
            onPressed: _showAddMeetingDialog,
          ),
          IconButton(
            icon: const Icon(Icons.class_),
            tooltip: l10n.addClassroom,
            onPressed: _showAddClassroomDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logoutSession(ref, context),
          ),
        ],
      ),
      bottomNavigationBar: const AppSectionBottomNavigationBar(
        currentIndex: 0,
        homeRoute: AppRoutes.superAdminHome,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: meetingsAsync.when(
          data: (meetings) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: Text(l10n.pendingAdmins),
                    subtitle: pendingAdminsAsync.when(
                      data: (list) => Text(
                        l10n.pendingCount.replaceAll(
                          '{count}',
                          list.length.toString(),
                        ),
                      ),
                      loading: () => Text(l10n.loadingLabel),
                      error: (e, _) => Text('${l10n.errorLabel} $e'),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.pendingAdmins),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.visibleMeetings,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (meetings.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l10n.noVisibleMeetingsFound),
                    ),
                  )
                else
                  ...meetings.map(
                    (m) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.groups),
                        title: Text(m.name ?? '-'),
                        subtitle: Text(
                          'Servants: ${m.servantsCount} • Members: ${m.membersCount}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: l10n.editMeetingTitle.replaceAll(
                                '{meeting}',
                                (m.name ?? ''),
                              ),
                              onPressed: () => _showEditMeetingDialog(m),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () {
                          final meetingId = m.id;
                          if (meetingId == null || meetingId <= 0) return;
                          context.push(
                            AppRoutes.classroomsHome,
                            extra: {
                              'meetingId': meetingId,
                              'meetingName': m.name ?? '',
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: Text(l10n.pendingAdmins),
                  subtitle: pendingAdminsAsync.when(
                    data: (list) => Text(
                      l10n.pendingCount.replaceAll(
                        '{count}',
                        list.length.toString(),
                      ),
                    ),
                    loading: () => Text(l10n.loadingLabel),
                    error: (e, _) => Text('${l10n.errorLabel} $e'),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.pendingAdmins),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.visibleMeetings,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: Text(l10n.pendingAdmins),
                  subtitle: pendingAdminsAsync.when(
                    data: (list) => Text(
                      l10n.pendingCount.replaceAll(
                        '{count}',
                        list.length.toString(),
                      ),
                    ),
                    loading: () => Text(l10n.loadingLabel),
                    error: (err, _) => Text('${l10n.errorLabel} $err'),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.pendingAdmins),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.visibleMeetings,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('${l10n.failedToLoadVisibleMeetings} $e'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
