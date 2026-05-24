import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/servants_providers.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/app_network_avatar.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../../unified_form/providers/unified_form_providers.dart';
import '../../unified_form/utils/unified_form_controller.dart';
import '../../unified_form/widgets/unified_entity_form.dart';

class ServantEditScreen extends ConsumerStatefulWidget {
  final int id;
  const ServantEditScreen({super.key, required this.id});

  @override
  ConsumerState<ServantEditScreen> createState() => _ServantEditScreenState();
}

class _ServantEditScreenState extends ConsumerState<ServantEditScreen> {
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
      await ref.read(unifiedFormRepositoryProvider).saveFormData(
            UnifiedEntityNames.servant,
            widget.id,
            _formController.buildSavePayload(fields),
          );

      if (_image != null) {
        await ref.read(servantsRepositoryProvider).update(
              widget.id,
              image: _image,
            );
      }

      if (mounted) {
        showSuccessSnackbar(context, l10n.servantUpdatedSuccessfully);
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
    final formAsync = ref.watch(
      entityFormDataProvider((entity: UnifiedEntityNames.servant, id: widget.id)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editServant)),
      body: formAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (formData) {
          if (!_initialized) {
            _formController.initializeFromFields(
              formData.fields,
              withValues: formData.fields,
            );
            _initialized = true;
          }

          final imageUrl = formData.fields
              .where((f) => f.fieldKey == 'imageUrl')
              .map((f) => f.value)
              .firstOrNull;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Center(
                    child: _image != null
                        ? CircleAvatar(radius: 48, backgroundImage: FileImage(_image!))
                        : AppNetworkAvatar(
                            imageUrl: imageUrl,
                            radius: 48,
                            placeholder: const Icon(Icons.camera_alt, size: 36),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                UnifiedEntityForm(
                  fields: formData.fields,
                  controller: _formController,
                ),
                const SizedBox(height: 24),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: () => _submit(formData.fields),
                        child: Text(l10n.save),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}
