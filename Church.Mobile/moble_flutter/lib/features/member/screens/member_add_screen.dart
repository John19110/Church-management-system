import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/app_form_shell.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../classroom/providers/classroom_providers.dart';
import '../../meeting/providers/meeting_providers.dart';
import '../../unified_form/widgets/unified_entity_photo_picker.dart';
import '../providers/members_providers.dart';
import '../utils/member_form_controller.dart';
import '../utils/member_native_form_mapper.dart';
import '../widgets/member_form.dart';

class MemberAddScreen extends ConsumerStatefulWidget {
  final int? classroomId;

  /// When opening Add Member from a meeting-scoped list, only classrooms
  /// belonging to this meeting are shown (when the meeting uses classrooms).
  final int? meetingId;

  const MemberAddScreen({super.key, this.classroomId, this.meetingId});

  @override
  ConsumerState<MemberAddScreen> createState() => _MemberAddScreenState();
}

class _MemberAddScreenState extends ConsumerState<MemberAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _memberForm = MemberFormController();
  File? _image;
  bool _loading = false;
  int? _selectedClassroomId;

  @override
  void initState() {
    super.initState();
    _selectedClassroomId = widget.classroomId;
  }

  @override
  void dispose() {
    _memberForm.dispose();
    super.dispose();
  }

  int? get _resolvedClassroomId => _selectedClassroomId ?? widget.classroomId;

  Future<void> _pickImage() async {
    final file = await pickUnifiedEntityPhoto();
    if (file != null) setState(() => _image = file);
  }

  void _rebuild() => setState(() {});

  bool _meetingUsesClassrooms(WidgetRef ref) {
    final meetingId = widget.meetingId;
    if (meetingId == null || meetingId <= 0) return true;
    final meetings = ref.watch(visibleMeetingsProvider).valueOrNull;
    if (meetings == null) return true;
    for (final m in meetings) {
      if (m.id == meetingId) return m.hasClassrooms;
    }
    return true;
  }

  Future<void> _submit({required bool usesClassrooms}) async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);
    final meetingId = widget.meetingId;

    if (!usesClassrooms) {
      if (meetingId == null || meetingId <= 0) {
        showErrorSnackbar(context, l10n.missingRequiredData);
        return;
      }
      setState(() => _loading = true);
      try {
        final dto = MemberNativeFormMapper.toAddDto(_memberForm);
        final memberId = await ref
            .read(membersRepositoryProvider)
            .createForMeeting(meetingId, dto, image: _image);

        ref.invalidate(membersListProvider);
        ref.invalidate(membersByMeetingProvider(meetingId));

        if (mounted) {
          showSuccessSnackbar(context, l10n.memberAddedSuccessfully);
          context.pop(memberId);
        }
      } catch (e) {
        if (mounted) showErrorSnackbar(context, userFriendlyMessage(e, l10n));
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      return;
    }

    final classroomId = _resolvedClassroomId ?? 0;
    if (classroomId <= 0) {
      showErrorSnackbar(context, l10n.pleaseSelectClassroom);
      return;
    }

    setState(() => _loading = true);
    try {
      final dto = MemberNativeFormMapper.toAddDto(_memberForm);
      final memberId = await ref
          .read(membersRepositoryProvider)
          .create(classroomId, dto, image: _image, meetingId: meetingId);

      ref.invalidate(membersListProvider);
      ref.invalidate(membersByClassroomProvider(classroomId));
      if (meetingId != null && meetingId > 0) {
        ref.invalidate(membersByMeetingProvider(meetingId));
      }

      if (mounted) {
        showSuccessSnackbar(context, l10n.memberAddedSuccessfully);
        context.pop(memberId);
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, userFriendlyMessage(e, l10n));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final meetingId = widget.meetingId;
    final usesClassrooms = _meetingUsesClassrooms(ref);
    final classroomsAsync = (meetingId != null && meetingId > 0)
        ? ref.watch(visibleClassroomsByMeetingProvider(meetingId))
        : ref.watch(visibleClassroomsProvider);
    final needsClassroomPicker =
        usesClassrooms && (widget.classroomId ?? 0) <= 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(l10n.addMember)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: AppFormListView(
            padding: const EdgeInsets.all(AppSpacing.page),
            children: [
              if (needsClassroomPicker)
                classroomsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(userFriendlyMessage(e, l10n)),
                  data: (classrooms) {
                    final scoped = (meetingId != null && meetingId > 0)
                        ? classrooms
                              .where((c) => c.meetingId == meetingId)
                              .toList()
                        : classrooms;
                    if (scoped.isEmpty) {
                      return Text(l10n.noVisibleClassroomsFound);
                    }
                    final options = scoped.where((c) => c.id != null).toList();
                    final selectedId = _selectedClassroomId;
                    final validSelection =
                        selectedId != null &&
                        options.any((c) => c.id == selectedId);
                    return DropdownButtonFormField<int>(
                      value: validSelection ? selectedId : null,
                      decoration: InputDecoration(
                        labelText: l10n.selectClassroom,
                      ),
                      items: options
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name ?? l10n.classroom),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedClassroomId = v),
                      validator: (v) =>
                          v == null ? l10n.pleaseSelectClassroom : null,
                    );
                  },
                ),
              if (needsClassroomPicker) const SizedBox(height: AppSpacing.md),
              MemberForm(
                controller: _memberForm,
                pickedImage: _image,
                onPickImage: _pickImage,
                onChanged: _rebuild,
              ),
              const SizedBox(height: AppSpacing.xl),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton(
                      onPressed: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        _submit(usesClassrooms: usesClassrooms);
                      },
                      child: Text(l10n.add),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
