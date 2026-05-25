import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../../classroom/providers/classroom_providers.dart';
import '../../custom_field/providers/custom_field_cache_providers.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../../unified_form/providers/unified_form_providers.dart';
import '../../unified_form/utils/unified_form_controller.dart';
import '../../unified_form/utils/unified_form_screen_mixin.dart';
import '../../unified_form/widgets/unified_entity_form.dart';
import '../providers/members_providers.dart';
import '../models/member_models.dart';

class MemberAddScreen extends ConsumerStatefulWidget {
  final int? classroomId;

  const MemberAddScreen({super.key, this.classroomId});

  @override
  ConsumerState<MemberAddScreen> createState() => _MemberAddScreenState();
}

class _MemberAddScreenState extends ConsumerState<MemberAddScreen>
    with UnifiedFormScreenMixin {
  final _formKey = GlobalKey<FormState>();
  final _formController = UnifiedFormController();
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
    _formController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
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

    final classroomId = _selectedClassroomId ?? widget.classroomId ?? 0;
    if (classroomId <= 0) {
      showErrorSnackbar(context, AppLocalizations.of(context).pleaseSelectClassroom);
      return;
    }

    setState(() => _loading = true);
    final l10n = AppLocalizations.of(context);
    try {
      final memberId = await ref.read(unifiedFormRepositoryProvider).createFromForm(
            UnifiedEntityNames.member,
            _formController.buildSavePayload(fields),
            classroomIdForMember: classroomId,
          );

      if (_image != null) {
        await ref.read(membersRepositoryProvider).updateWithImage(
              memberId,
              MemberUpdateDto(id: memberId),
              image: _image!,
            );
      }

      if (mounted) {
        showSuccessSnackbar(context, l10n.memberAddedSuccessfully);
        context.pop(memberId);
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
        entityFormSchemaProvider((entity: UnifiedEntityNames.member, mode: 'Create')),
      );
      resetFormSignature();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final roleAsync = ref.watch(currentUserRoleProvider);
    final schemaAsync = ref.watch(
      entityFormSchemaProvider((entity: UnifiedEntityNames.member, mode: 'Create')),
    );
    final classroomsAsync = ref.watch(visibleClassroomsProvider);
    final needsClassroomPicker = (widget.classroomId ?? 0) <= 0;

    return roleAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.addMember)),
        body: const LoadingWidget(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.addMember)),
        body: AppErrorWidget(message: e.toString()),
      ),
      data: (role) {
        final canManage = AuthRoleUtils.canManageCustomFields(role);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.addMember),
            actions: [
              if (canManage)
                IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: l10n.manageCustomFields,
                  onPressed: _openFieldSettings,
                ),
            ],
          ),
          body: schemaAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => AppErrorWidget(message: e.toString()),
            data: (schema) {
              syncFormController(_formController, schema.fields);

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (needsClassroomPicker)
                      classroomsAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('${l10n.errorLabel} $e'),
                        data: (classrooms) {
                          if (classrooms.isEmpty) {
                            return Text(l10n.noVisibleClassroomsFound);
                          }
                          return DropdownButtonFormField<int>(
                            value: _selectedClassroomId,
                            decoration: InputDecoration(
                              labelText: l10n.selectClassroom,
                            ),
                            items: classrooms
                                .where((c) => c.id != null)
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name ?? '${c.id}'),
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
                    GestureDetector(
                      onTap: _pickImage,
                      child: Center(
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceContainerHighest,
                          backgroundImage:
                              _image != null ? FileImage(_image!) : null,
                          child: _image == null
                              ? const Icon(Icons.camera_alt, size: 36)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    UnifiedEntityForm(
                      fields: schema.fields,
                      controller: _formController,
                      entityName: UnifiedEntityNames.member,
                      configurationHint: schema.configurationHint,
                      canManageDefinitions: canManage,
                    ),
                    const SizedBox(height: 24),
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : FilledButton(
                            onPressed: schema.fields.isEmpty
                                ? null
                                : () => _submit(schema.fields),
                            child: Text(l10n.add),
                          ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
