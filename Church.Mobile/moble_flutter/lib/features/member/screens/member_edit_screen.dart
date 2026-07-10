import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../unified_form/widgets/unified_entity_photo_picker.dart';
import '../providers/members_providers.dart';
import '../utils/member_form_controller.dart';
import '../utils/member_native_form_mapper.dart';
import '../widgets/member_form.dart';

class MemberEditScreen extends ConsumerStatefulWidget {
  final int id;
  const MemberEditScreen({super.key, required this.id});

  @override
  ConsumerState<MemberEditScreen> createState() => _MemberEditScreenState();
}

class _MemberEditScreenState extends ConsumerState<MemberEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _memberForm = MemberFormController();
  File? _image;
  bool _loading = false;
  bool _initialized = false;
  int? _classroomId;

  @override
  void dispose() {
    _memberForm.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await pickUnifiedEntityPhoto();
    if (file != null) setState(() => _image = file);
  }

  void _rebuild() => setState(() {});

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final l10n = AppLocalizations.of(context);
    try {
      final dto = MemberNativeFormMapper.toUpdateDto(_memberForm, widget.id);
      await ref.read(membersRepositoryProvider).updateMember(
            widget.id,
            dto,
            image: _image,
          );

      ref.invalidate(memberDetailProvider(widget.id));
      ref.invalidate(membersListProvider);
      if (_classroomId != null) {
        ref.invalidate(membersByClassroomProvider(_classroomId!));
      }

      if (mounted) {
        showSuccessSnackbar(context, l10n.memberUpdatedSuccessfully);
        context.pop(true);
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
    if (widget.id <= 0) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.editMember)),
        body: AppErrorWidget(
          message: l10n.invalidMemberId,
          onRetry: () {
            if (context.mounted) context.pop();
          },
        ),
      );
    }

    final memberAsync = ref.watch(memberDetailProvider(widget.id));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editMember)),
      body: SafeArea(
        child: memberAsync.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => AppErrorWidget(
            message: userFriendlyMessage(e, l10n),
            onRetry: () => ref.invalidate(memberDetailProvider(widget.id)),
          ),
          data: (member) {
            if (!_initialized) {
              _memberForm.loadFromMember(member);
              _classroomId = member.classroomId;
              _initialized = true;
            }

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  MemberForm(
                    controller: _memberForm,
                    pickedImage: _image,
                    onPickImage: _pickImage,
                    onChanged: _rebuild,
                    showLastAttendanceDate: true,
                  ),
                  const SizedBox(height: 24),
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : FilledButton(
                          onPressed: _submit,
                          child: Text(l10n.save),
                        ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
