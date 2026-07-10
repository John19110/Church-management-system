import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../classroom/providers/classroom_providers.dart';
import '../../unified_form/widgets/unified_entity_photo_picker.dart';
import '../providers/members_providers.dart';
import '../utils/member_form_controller.dart';
import '../utils/member_native_form_mapper.dart';
import '../widgets/member_form.dart';

class MemberAddScreen extends ConsumerStatefulWidget {
  final int? classroomId;

  const MemberAddScreen({super.key, this.classroomId});

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final classroomId = _resolvedClassroomId ?? 0;
    final l10n = AppLocalizations.of(context);
    if (classroomId <= 0) {
      showErrorSnackbar(context, l10n.pleaseSelectClassroom);
      return;
    }

    setState(() => _loading = true);
    try {
      final dto = MemberNativeFormMapper.toAddDto(_memberForm);
      final memberId = await ref.read(membersRepositoryProvider).create(
            classroomId,
            dto,
            image: _image,
          );

      ref.invalidate(membersListProvider);
      ref.invalidate(membersByClassroomProvider(classroomId));

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
    final classroomsAsync = ref.watch(visibleClassroomsProvider);
    final needsClassroomPicker = (widget.classroomId ?? 0) <= 0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addMember)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (needsClassroomPicker)
                classroomsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(userFriendlyMessage(e, l10n)),
                  data: (classrooms) {
                    if (classrooms.isEmpty) {
                      return Text(l10n.noVisibleClassroomsFound);
                    }
                    final options =
                        classrooms.where((c) => c.id != null).toList();
                    final selectedId = _selectedClassroomId;
                    final validSelection = selectedId != null &&
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
                      onChanged: (v) => setState(() => _selectedClassroomId = v),
                      validator: (v) =>
                          v == null ? l10n.pleaseSelectClassroom : null,
                    );
                  },
                ),
              if (needsClassroomPicker) const SizedBox(height: 16),
              MemberForm(
                controller: _memberForm,
                pickedImage: _image,
                onPickImage: _pickImage,
                onChanged: _rebuild,
              ),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton(
                      onPressed: _submit,
                      child: Text(l10n.add),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
