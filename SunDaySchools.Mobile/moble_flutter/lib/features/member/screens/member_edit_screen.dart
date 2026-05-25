import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/member_models.dart';
import '../providers/members_providers.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../auth/providers/auth_providers.dart';
import '../../unified_form/widgets/unified_entity_photo_picker.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../../custom_field/providers/custom_field_cache_providers.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../../unified_form/providers/unified_form_providers.dart';
import '../../unified_form/utils/unified_form_controller.dart';
import '../../unified_form/utils/unified_form_screen_mixin.dart';
import '../../unified_form/widgets/unified_entity_form.dart';

class MemberEditScreen extends ConsumerStatefulWidget {
  final int id;
  const MemberEditScreen({super.key, required this.id});

  @override
  ConsumerState<MemberEditScreen> createState() => _MemberEditScreenState();
}

class _MemberEditScreenState extends ConsumerState<MemberEditScreen>
    with UnifiedFormScreenMixin {
  final _formKey = GlobalKey<FormState>();
  final _formController = UnifiedFormController();
  File? _image;
  bool _loading = false;

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await pickUnifiedEntityPhoto();
    if (file != null) setState(() => _image = file);
  }

  Future<void> _submit(List<UnifiedFieldDefinitionDto> fields) async {
    if (!_formKey.currentState!.validate()) return;
    if (fields.isEmpty) {
      showErrorSnackbar(
        context,
        AppLocalizations.of(context).entityFieldsNotConfigured,
      );
      return;
    }

    setState(() => _loading = true);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(unifiedFormRepositoryProvider).saveFormData(
            UnifiedEntityNames.member,
            widget.id,
            _formController.buildSavePayload(fields),
          );

      if (_image != null) {
        await ref.read(membersRepositoryProvider).updateWithImage(
              widget.id,
              MemberUpdateDto(id: widget.id),
              image: _image!,
            );
      }

      ref.invalidate(
        entityFormDataProvider((entity: UnifiedEntityNames.member, id: widget.id)),
      );

      if (mounted) {
        showSuccessSnackbar(context, l10n.memberUpdatedSuccessfully);
        context.pop(true);
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openFieldSettings() async {
    await context.push('/custom-fields/Member');
    if (mounted) {
      refreshEntityFormsAfterDefinitionChange(ref, UnifiedEntityNames.member);
      ref.invalidate(
        entityFormDataProvider((entity: UnifiedEntityNames.member, id: widget.id)),
      );
      resetFormSignature();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.id <= 0) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.editMember)),
        body: AppErrorWidget(
          message: 'Invalid member id.',
          onRetry: () {
            if (context.mounted) context.pop();
          },
        ),
      );
    }

    final roleAsync = ref.watch(currentUserRoleProvider);
    final formAsync = ref.watch(
      entityFormDataProvider((entity: UnifiedEntityNames.member, id: widget.id)),
    );

    return roleAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.editMember)),
        body: const LoadingWidget(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.editMember)),
        body: AppErrorWidget(message: e.toString()),
      ),
      data: (role) {
        final canManage = AuthRoleUtils.canManageCustomFields(role);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.editMember),
            actions: [
              if (canManage)
                IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: l10n.manageCustomFields,
                  onPressed: _openFieldSettings,
                ),
            ],
          ),
          body: SafeArea(
            child: formAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(
                  entityFormDataProvider((
                    entity: UnifiedEntityNames.member,
                    id: widget.id,
                  )),
                ),
              ),
              data: (formData) {
                syncFormController(
                  _formController,
                  formData.fields,
                  withValues: formData.fields,
                );

                return Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      UnifiedEntityPhotoPicker(
                        fields: formData.fields,
                        pickedFile: _image,
                        onPick: _pickImage,
                      ),
                      const SizedBox(height: 16),
                      UnifiedEntityForm(
                        fields: formData.fields,
                        controller: _formController,
                        entityName: UnifiedEntityNames.member,
                        canManageDefinitions: canManage,
                      ),
                      const SizedBox(height: 24),
                      _loading
                          ? const Center(child: CircularProgressIndicator())
                          : FilledButton(
                              onPressed: formData.fields.isEmpty
                                  ? null
                                  : () => _submit(formData.fields),
                              child: Text(l10n.save),
                            ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
