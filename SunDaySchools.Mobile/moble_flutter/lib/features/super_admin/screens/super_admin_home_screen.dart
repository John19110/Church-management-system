import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/startup/deferred_startup_mixin.dart';
import '../../../core/routing/app_router.dart';
import '../../auth/utils/auth_session.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../meeting/models/meeting_models.dart';
import '../../meeting/providers/meeting_providers.dart';
import '../../../shared/widgets/app_section_bottom_navigation_bar.dart';
import '../providers/super_admin_providers.dart';

class SuperAdminHomeScreen extends ConsumerStatefulWidget {
  const SuperAdminHomeScreen({super.key});

  @override
  ConsumerState<SuperAdminHomeScreen> createState() =>
      _SuperAdminHomeScreenState();
}

class _SuperAdminHomeScreenState extends ConsumerState<SuperAdminHomeScreen>
    with DeferredStartupMixin {
  final _meetingFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _timeController = TextEditingController();

  TimeOfDay? _selectedTime;
  String _selectedDay = 'Saturday';

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
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
    try {
      await ref.read(visibleMeetingsProvider.future);
    } catch (_) {
      // AsyncValue on the home screen shows the error; avoid crashing pull-to-refresh.
    }
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
                          hintText: l10n.timeFormatHint,
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
                            showErrorSnackbar(
                              context,
                              userFriendlyMessage(
                                e,
                                AppLocalizations.of(context),
                              ),
                            );
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

  Widget _buildMeetingsList(
    AppLocalizations l10n,
    AsyncValue<List<MeetingReadDto>> meetingsAsync,
  ) {
    return meetingsAsync.when(
      data: (meetings) {
        if (meetings.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.noVisibleMeetingsFound),
            ),
          );
        }

        return Column(
          children: meetings
              .map(
                (m) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.groups),
                    title: Text(m.name ?? l10n.notAvailable),
                    subtitle: Text(
                      l10n.meetingServantsMembersSummary(
                        m.servantsCount,
                        m.membersCount,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
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
              )
              .toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            userFriendlyMessage(e, l10n),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final meetingsAsync = deferredReady
        ? ref.watch(visibleMeetingsProvider)
        : const AsyncValue<List<MeetingReadDto>>.loading();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.superAdminHome),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logoutSession(ref, context),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _showAddMeetingDialog,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addMeeting),
                ),
              ),
            ),
          ),
          const AppSectionBottomNavigationBar(
            currentIndex: 0,
            homeRoute: AppRoutes.superAdminHome,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.visibleMeetings,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildMeetingsList(l10n, meetingsAsync),
          ],
        ),
      ),
    );
  }
}
