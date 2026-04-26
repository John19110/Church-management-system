import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      throw const FormatException('Weekly appointment time is required.');
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
            return AlertDialog(
              title: const Text('Add Meeting'),
              content: SingleChildScrollView(
                child: Form(
                  key: _meetingFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Meeting Name',
                          hintText: 'Enter meeting name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Meeting name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedDay,
                        decoration: const InputDecoration(
                          labelText: 'Day of week',
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Saturday', child: Text('Saturday')),
                          DropdownMenuItem(
                              value: 'Sunday', child: Text('Sunday')),
                          DropdownMenuItem(
                              value: 'Monday', child: Text('Monday')),
                          DropdownMenuItem(
                              value: 'Tuesday', child: Text('Tuesday')),
                          DropdownMenuItem(
                              value: 'Wednesday', child: Text('Wednesday')),
                          DropdownMenuItem(
                              value: 'Thursday', child: Text('Thursday')),
                          DropdownMenuItem(
                              value: 'Friday', child: Text('Friday')),
                        ],
                        onChanged: isSubmitting
                            ? null
                            : (v) {
                                if (v == null) return;
                                if (!dialogBuilderContext.mounted) return;
                                setDialogState(() => _selectedDay = v);
                              },
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Day of week is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _timeController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Weekly appointment time',
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
                            ? 'Weekly appointment time is required'
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
                  child: const Text('Cancel'),
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
                              'Meeting added successfully.',
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
                      : const Text('Add'),
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
            return AlertDialog(
              title: const Text('Add Classroom'),
              content: SingleChildScrollView(
                child: Form(
                  key: _classroomFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _classroomNameController,
                        decoration: const InputDecoration(
                          labelText: 'Classroom Name',
                          hintText: 'Enter classroom name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Classroom name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _classroomAgeController,
                        decoration: const InputDecoration(
                          labelText: 'Age of Members',
                          hintText: 'Enter age range',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Age of members is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      EndpointSelectDropdown(
                        endpoint: SelectionEndpoints.meetings,
                        label: 'Meeting (optional)',
                        hintText: 'Select meeting',
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
                  child: const Text('Cancel'),
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
                              'Classroom added successfully.',
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
                      : const Text('Add'),
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
            return AlertDialog(
              title: Text('Edit Meeting: ${meeting.name ?? meetingId}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EndpointSelectDropdown(
                      endpoint: SelectionEndpoints.servants,
                      label: 'Leader Servant (optional)',
                      hintText: 'Select servant',
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
                  child: const Text('Cancel'),
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
                            showSuccessSnackbar(context, 'Meeting updated.');
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
                      : const Text('Save'),
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
    final meetingsAsync = ref.watch(visibleMeetingsProvider);
    final pendingAdminsAsync = ref.watch(pendingAdminsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Meeting',
            onPressed: _showAddMeetingDialog,
          ),
          IconButton(
            icon: const Icon(Icons.class_),
            tooltip: 'Add Classroom',
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
                    title: const Text('Pending Admins'),
                    subtitle: pendingAdminsAsync.when(
                      data: (list) => Text('${list.length} pending'),
                      loading: () => const Text('Loading...'),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.pendingAdmins),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Visible Meetings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (meetings.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No visible meetings found.'),
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
                              tooltip: 'Edit meeting',
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
                  title: const Text('Pending Admins'),
                  subtitle: pendingAdminsAsync.when(
                    data: (list) => Text('${list.length} pending'),
                    loading: () => const Text('Loading...'),
                    error: (e, _) => Text('Error: $e'),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.pendingAdmins),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Visible Meetings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  title: const Text('Pending Admins'),
                  subtitle: pendingAdminsAsync.when(
                    data: (list) => Text('${list.length} pending'),
                    loading: () => const Text('Loading...'),
                    error: (err, _) => Text('Error: $err'),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.pendingAdmins),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Visible Meetings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Failed to load visible meetings: $e'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
