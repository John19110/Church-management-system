import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/app_form_shell.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/providers/auth_providers.dart';
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
  void initState() {
    super.initState();
    resetFormSignature();
  }

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await pickUnifiedEntityPhoto();
    if (file != null) setState(() => _image = file);
  }

  List<UnifiedFieldDefinitionDto> _editableFields(List<UnifiedFieldDto> fields) {
    return fields
        .where(
          (f) =>
              !f.isHidden &&
              !f.isReadOnly &&
              !kServantProfileReadOnlyFieldKeys.contains(f.fieldKey),
        )
        .toList();
  }

  Future<void> _submit(List<UnifiedFieldDto> fields) async {
    if (!_formKey.currentState!.validate()) return;

    final editable = _editableFields(fields);
    if (editable.isEmpty && _image == null) {
      showErrorSnackbar(
        context,
        AppLocalizations.of(context).entityFieldsNotConfigured,
      );
      return;
    }

    setState(() => _loading = true);
    final l10n = AppLocalizations.of(context);
    try {
      if (editable.isNotEmpty) {
        await ref.read(servantsRepositoryProvider).saveProfileFormData(
              _formController.buildSavePayload(editable),
            );
      }

      if (_image != null) {
        await ref.read(servantsRepositoryProvider).updateProfile(image: _image);
      }

      ref.invalidate(servantProfileProvider);
      ref.invalidate(servantProfileFormDataProvider);
      ref.read(authSessionEpochProvider.notifier).state++;

      final profile = await ref.read(servantProfileProvider.future);
      ref.invalidate(
        entityFormDataProvider((
          entity: UnifiedEntityNames.servant,
          id: profile.id,
        )),
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
    final formAsync = ref.watch(servantProfileFormDataProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(l10n.editProfile)),
      body: profileAsync.when(
        loading: () => const LoadingWidget(useSkeleton: true),
        error: (e, _) => AppErrorWidget(
          message: userFriendlyMessage(e, l10n),
          onRetry: () {
            ref.invalidate(servantProfileProvider);
            ref.invalidate(servantProfileFormDataProvider);
          },
        ),
        data: (profile) {
          if (profile.id <= 0) {
            return AppErrorWidget(message: l10n.failedToLoadProfile);
          }

          return formAsync.when(
            loading: () => const LoadingWidget(useSkeleton: true),
            error: (e, _) => AppErrorWidget(
              message: userFriendlyMessage(e, l10n),
              onRetry: () => ref.invalidate(servantProfileFormDataProvider),
            ),
            data: (formData) {
              syncFormController(
                _formController,
                formData.fields,
                withValues: formData.fields,
              );

              final editable = _editableFields(formData.fields);

              return SafeArea(
                child: Form(
                  key: _formKey,
                  child: AppFormListView(
                    padding: const EdgeInsets.all(AppSpacing.page),
                    children: [
                      UnifiedEntityPhotoPicker(
                        fields: formData.fields,
                        imageUrl: profile.displayImageUrl,
                        pickedFile: _image,
                        onPick: _pickImage,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      UnifiedEntityForm(
                        fields: formData.fields,
                        controller: _formController,
                        entityName: UnifiedEntityNames.servant,
                        excludeFieldKeys: kServantProfileReadOnlyFieldKeys,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _loading
                          ? const Center(child: CircularProgressIndicator())
                          : FilledButton(
                              onPressed: (editable.isEmpty && _image == null)
                                  ? null
                                  : () {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      _submit(formData.fields);
                                    },
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
