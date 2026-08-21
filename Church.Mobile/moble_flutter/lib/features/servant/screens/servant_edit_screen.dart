import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/servants_providers.dart';
import '../../../shared/widgets/app_form_shell.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_dimens.dart';
import '../../unified_form/widgets/unified_entity_photo_picker.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../../unified_form/providers/unified_form_providers.dart';
import '../../unified_form/utils/unified_form_controller.dart';
import '../../unified_form/utils/unified_form_screen_mixin.dart';
import '../../unified_form/widgets/unified_entity_form.dart';

class ServantEditScreen extends ConsumerStatefulWidget {
  final int id;
  const ServantEditScreen({super.key, required this.id});

  @override
  ConsumerState<ServantEditScreen> createState() => _ServantEditScreenState();
}

class _ServantEditScreenState extends ConsumerState<ServantEditScreen>
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

      ref.invalidate(
        entityFormDataProvider((entity: UnifiedEntityNames.servant, id: widget.id)),
      );

      if (mounted) {
        showSuccessSnackbar(context, l10n.servantUpdatedSuccessfully);
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, userFriendlyMessage(e, l10n));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final roleAsync = ref.watch(currentUserRoleProvider);
    final formAsync = ref.watch(
      entityFormDataProvider((entity: UnifiedEntityNames.servant, id: widget.id)),
    );

    return roleAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.editServant)),
        body: const LoadingWidget(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.editServant)),
        body: AppErrorWidget(message: userFriendlyMessage(e, l10n)),
      ),
      data: (role) {
        final canManage = AuthRoleUtils.canManageCustomFields(role);

        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: Text(l10n.editServant),
          ),
          body: formAsync.when(
            loading: () => const LoadingWidget(useSkeleton: true),
            error: (e, _) => AppErrorWidget(
              message: userFriendlyMessage(e, l10n),
              onRetry: () => ref.invalidate(
                entityFormDataProvider(
                  (entity: UnifiedEntityNames.servant, id: widget.id),
                ),
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
                child: AppFormListView(
                  padding: const EdgeInsets.all(AppSpacing.page),
                  children: [
                    UnifiedEntityPhotoPicker(
                      fields: formData.fields,
                      pickedFile: _image,
                      onPick: _pickImage,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    UnifiedEntityForm(
                      fields: formData.fields,
                      controller: _formController,
                      entityName: UnifiedEntityNames.servant,
                      canManageDefinitions: canManage,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : FilledButton(
                            onPressed: formData.fields.isEmpty
                                ? null
                                : () {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    _submit(formData.fields);
                                  },
                            child: Text(l10n.save),
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
