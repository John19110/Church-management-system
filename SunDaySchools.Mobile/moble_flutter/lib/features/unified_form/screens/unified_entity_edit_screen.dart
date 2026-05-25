import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../../custom_field/providers/custom_field_cache_providers.dart';
import '../models/unified_form_models.dart';
import '../providers/unified_form_providers.dart';
import '../utils/unified_form_controller.dart';
import '../utils/unified_form_screen_mixin.dart';
import '../widgets/unified_entity_form.dart';

/// Generic edit screen driven by unified form-data API.
class UnifiedEntityEditScreen extends ConsumerStatefulWidget {
  final String entityName;
  final int entityId;
  final String? title;

  const UnifiedEntityEditScreen({
    super.key,
    required this.entityName,
    required this.entityId,
    this.title,
  });

  @override
  ConsumerState<UnifiedEntityEditScreen> createState() =>
      _UnifiedEntityEditScreenState();
}

class _UnifiedEntityEditScreenState extends ConsumerState<UnifiedEntityEditScreen>
    with UnifiedFormScreenMixin {
  final _formKey = GlobalKey<FormState>();
  final _controller = UnifiedFormController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(List<UnifiedFieldDefinitionDto> fields) async {
    if (!_formKey.currentState!.validate()) return;
    if (fields.isEmpty) {
      showErrorSnackbar(
        context,
        AppLocalizations.of(context).entityFieldsNotConfigured,
      );
      return;
    }

    final l10n = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      await ref.read(unifiedFormRepositoryProvider).saveFormData(
            widget.entityName,
            widget.entityId,
            _controller.buildSavePayload(fields),
          );
      ref.invalidate(
        entityFormDataProvider((entity: widget.entityName, id: widget.entityId)),
      );
      if (mounted) {
        showSuccessSnackbar(context, l10n.changesSaved);
        context.pop(true);
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openFieldSettings() async {
    await context.push('/custom-fields/${widget.entityName}');
    if (mounted) {
      refreshEntityFormsAfterDefinitionChange(ref, widget.entityName);
      ref.invalidate(
        entityFormDataProvider((entity: widget.entityName, id: widget.entityId)),
      );
      resetFormSignature();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final roleAsync = ref.watch(currentUserRoleProvider);
    final formAsync = ref.watch(
      entityFormDataProvider((entity: widget.entityName, id: widget.entityId)),
    );

    return roleAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title ?? l10n.customFieldsForEntity(widget.entityName),
          ),
        ),
        body: const LoadingWidget(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title ?? l10n.customFieldsForEntity(widget.entityName),
          ),
        ),
        body: AppErrorWidget(message: e.toString()),
      ),
      data: (role) {
        final canManage = AuthRoleUtils.canManageCustomFields(role);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.title ??
                  l10n.customFieldsForEntity(widget.entityName),
            ),
            actions: [
              if (canManage)
                IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: l10n.manageCustomFields,
                  onPressed: _openFieldSettings,
                ),
            ],
          ),
          body: formAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => AppErrorWidget(message: e.toString()),
            data: (data) {
              syncFormController(
                _controller,
                data.fields,
                withValues: data.fields,
              );

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    UnifiedEntityForm(
                      fields: data.fields,
                      controller: _controller,
                      entityName: widget.entityName,
                      canManageDefinitions: canManage,
                    ),
                    const SizedBox(height: 24),
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : FilledButton(
                            onPressed: data.fields.isEmpty
                                ? null
                                : () => _save(data.fields),
                            child: Text(l10n.saveLabel),
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
