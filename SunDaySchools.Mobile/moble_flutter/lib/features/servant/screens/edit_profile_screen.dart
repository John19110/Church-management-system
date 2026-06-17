import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../../unified_form/providers/unified_form_providers.dart';
import '../../unified_form/utils/unified_form_controller.dart';
import '../../unified_form/utils/unified_form_screen_mixin.dart';
import '../../unified_form/widgets/unified_entity_form.dart';
import '../../unified_form/widgets/unified_entity_photo_picker.dart';
import '../providers/servants_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
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

  Future<void> _submit(int servantId, List<UnifiedFieldDefinitionDto> fields) async {
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
            UnifiedEntityNames.servant,
            servantId,
            _formController.buildSavePayload(fields),
          );

      if (_image != null) {
        await ref.read(servantsRepositoryProvider).update(
              servantId,
              image: _image,
            );
      }

      ref.invalidate(servantProfileProvider);
      ref.invalidate(
        entityFormDataProvider((entity: UnifiedEntityNames.servant, id: servantId)),
      );

      if (mounted) {
        showSuccessSnackbar(context, l10n.profileUpdated);
        context.pop();
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
    final profileAsync = ref.watch(servantProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfile)),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: userFriendlyMessage(e, l10n),
          onRetry: () => ref.invalidate(servantProfileProvider),
        ),
        data: (profile) {
          if (profile.id <= 0) {
            return AppErrorWidget(message: l10n.failedToLoadProfile);
          }

          final formAsync = ref.watch(
            entityFormDataProvider((
              entity: UnifiedEntityNames.servant,
              id: profile.id,
            )),
          );

          return formAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorWidget(
              message: userFriendlyMessage(e, l10n),
              onRetry: () => ref.invalidate(
                entityFormDataProvider((
                  entity: UnifiedEntityNames.servant,
                  id: profile.id,
                )),
              ),
            ),
            data: (formData) {
              syncFormController(
                _formController,
                formData.fields,
                withValues: formData.fields,
              );

              return SafeArea(
                child: Form(
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
                        entityName: UnifiedEntityNames.servant,
                      ),
                      const SizedBox(height: 24),
                      _loading
                          ? const Center(child: CircularProgressIndicator())
                          : FilledButton(
                              onPressed: formData.fields.isEmpty
                                  ? null
                                  : () => _submit(profile.id, formData.fields),
                              child: Text(l10n.saveLabel),
                            ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
