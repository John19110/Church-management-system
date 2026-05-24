import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/members_providers.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../../unified_form/providers/unified_form_providers.dart';
import '../../unified_form/utils/member_form_mapper.dart';
import '../../unified_form/utils/unified_form_controller.dart';
import '../../unified_form/widgets/unified_entity_form.dart';

class MemberAddScreen extends ConsumerStatefulWidget {
  final int? classroomId;

  const MemberAddScreen({super.key, this.classroomId});

  @override
  ConsumerState<MemberAddScreen> createState() => _MemberAddScreenState();
}

class _MemberAddScreenState extends ConsumerState<MemberAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _formController = UnifiedFormController();
  File? _image;
  bool _loading = false;
  bool _initialized = false;

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
    setState(() => _loading = true);
    final l10n = AppLocalizations.of(context);
    try {
      final classroomId = widget.classroomId ?? 0;
      if (classroomId <= 0) {
        showErrorSnackbar(context, 'Classroom is required.');
        return;
      }

      final addDto = MemberFormMapper.toAddDto(_formController, fields);
      final memberId = await ref.read(membersRepositoryProvider).create(
            classroomId,
            addDto,
            image: _image,
          );

      await ref.read(unifiedFormRepositoryProvider).saveFormData(
            UnifiedEntityNames.member,
            memberId,
            _formController.buildSavePayload(fields),
          );

      if (mounted) {
        showSuccessSnackbar(context, l10n.memberAddedSuccessfully);
        context.pop();
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final schemaAsync = ref.watch(
      entityFormSchemaProvider((entity: UnifiedEntityNames.member, mode: 'Create')),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addMember)),
      body: schemaAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (schema) {
          if (!_initialized) {
            _formController.initializeFromFields(schema.fields);
            _initialized = true;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Center(
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      backgroundImage: _image != null ? FileImage(_image!) : null,
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
                ),
                const SizedBox(height: 24),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: () => _submit(schema.fields),
                        child: Text(l10n.addMember),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}
