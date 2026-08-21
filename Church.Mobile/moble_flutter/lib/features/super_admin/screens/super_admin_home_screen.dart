import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/weekday_l10n.dart';
import '../../../core/startup/deferred_startup_mixin.dart';
import '../../../core/routing/app_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../../auth/utils/auth_session.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/app_form_shell.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../meeting/models/meeting_models.dart';
import '../../meeting/providers/meeting_providers.dart';
import '../../meeting/utils/meeting_delete_actions.dart';
import '../../meeting/widgets/meeting_list_card.dart';
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
  bool _hasClassrooms = true;

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
    _hasClassrooms = true;
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
            hasClassrooms: _hasClassrooms,
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
              insetPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              title: Text(l10n.addMeeting),
              content: AppDialogFormBody(
                child: Form(
                  key: _meetingFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppTextField(
                        controller: _nameController,
                        label: l10n.meetingNameLabel,
                        hint: l10n.enterMeetingNameHint,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        enabled: !isSubmitting,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.meetingNameRequiredGeneric;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        value: _selectedDay,
                        decoration: InputDecoration(
                          labelText: l10n.meetingDayOfWeek,
                          errorMaxLines: 3,
                        ),
                        items: WeekdayL10n.dropdownItems(l10n),
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
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _timeController,
                        label: l10n.weeklyAppointmentTime,
                        hint: l10n.timeFormatHint,
                        readOnly: true,
                        enabled: !isSubmitting,
                        textInputAction: TextInputAction.done,
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
                      const SizedBox(height: AppSpacing.md),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          l10n.divideMeetingIntoClassroomsQuestion,
                          style: Theme.of(dialogBuilderContext)
                              .textTheme
                              .titleSmall,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.divideMeetingIntoClassroomsHint,
                        style:
                            Theme.of(dialogBuilderContext).textTheme.bodySmall,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _hasClassrooms
                              ? l10n.yesDivideIntoClassrooms
                              : l10n.noKeepMeetingWithoutClassrooms,
                        ),
                        value: _hasClassrooms,
                        onChanged: isSubmitting
                            ? null
                            : (v) =>
                                setDialogState(() => _hasClassrooms = v),
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
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(88, 48),
                  ),
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
    String? role,
  ) {
    final canEdit = AuthRoleUtils.canEditMeeting(role);
    final canDelete = AuthRoleUtils.canDeleteMeeting(role);

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
                (m) {
                  final meetingId = m.id;
                  return MeetingListCard(
                    meeting: m,
                    canEdit: canEdit,
                    canDelete: canDelete,
                    onOpen: () => context.push(
                      AppRoutes.meetingDetail,
                      extra: m,
                    ),
                    onEdit: canEdit && meetingId != null && meetingId > 0
                        ? () => context.push('/meetings/$meetingId/edit')
                        : null,
                    onDelete: canDelete && meetingId != null && meetingId > 0
                        ? () => confirmAndDeleteMeeting(
                              context,
                              ref,
                              meetingId: meetingId,
                              l10n: l10n,
                            )
                        : null,
                  );
                },
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
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
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
            _buildMeetingsList(l10n, meetingsAsync, role),
          ],
        ),
      ),
    );
  }
}
