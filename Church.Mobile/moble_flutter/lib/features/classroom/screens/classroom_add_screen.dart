import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../../custom_field/providers/custom_field_cache_providers.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../../unified_form/providers/unified_form_providers.dart';
import '../../unified_form/utils/unified_form_controller.dart';
import '../../unified_form/utils/unified_form_screen_mixin.dart';
import '../../unified_form/widgets/unified_entity_form.dart';
import '../providers/classroom_providers.dart';

class ClassroomAddScreen extends ConsumerStatefulWidget {
  final int? meetingId;

  const ClassroomAddScreen({super.key, this.meetingId});

  @override
  ConsumerState<ClassroomAddScreen> createState() => _ClassroomAddScreenState();
}

class _ClassroomAddScreenState extends ConsumerState<ClassroomAddScreen>
    with UnifiedFormScreenMixin {
  final _formKey = GlobalKey<FormState>();
  final _formController = UnifiedFormController();
  bool _loading = false;

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
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
      final id = await ref.read(unifiedFormRepositoryProvider).createFromForm(
            UnifiedEntityNames.classroom,
            _formController.buildSavePayload(fields),
            meetingIdForClassroom: widget.meetingId,
          );

      invalidateVisibleClassrooms(ref, meetingId: widget.meetingId);

      if (mounted) {
        showSuccessSnackbar(context, l10n.classroomAddedSuccessfully);
        context.pop(id);
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, userFriendlyMessage(e, l10n));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openFieldSettings() async {
    await context.push('/custom-fields/Classroom');
    if (mounted) {
      refreshEntityFormsAfterDefinitionChange(ref, UnifiedEntityNames.classroom);
      ref.invalidate(
        entityFormSchemaProvider((entity: UnifiedEntityNames.classroom, mode: 'Create')),
      );
      resetFormSignature();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final roleAsync = ref.watch(currentUserRoleProvider);
    final schemaAsync = ref.watch(
      entityFormSchemaProvider((entity: UnifiedEntityNames.classroom, mode: 'Create')),
    );

    return roleAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.addClassroom)),
        body: const LoadingWidget(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.addClassroom)),
        body: AppErrorWidget(message: userFriendlyMessage(e, l10n)),
      ),
      data: (role) {
        final canManage = AuthRoleUtils.canManageCustomFields(role);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.addClassroom),
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
            error: (e, _) => AppErrorWidget(message: userFriendlyMessage(e, l10n)),
            data: (schema) {
              syncFormController(_formController, schema.fields);

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    UnifiedEntityForm(
                      fields: schema.fields,
                      controller: _formController,
                      entityName: UnifiedEntityNames.classroom,
                      configurationHint: schema.configurationHint,
                      canManageDefinitions: canManage,
                      excludeFieldKeys: const {
                        'imageUrl',
                        'totalMembersCount',
                        // Backend key uses this legacy typo in multiple places.
                        'numberOfDisplineMembers',
                        // Defensive support if backend/schema spelling is corrected.
                        'numberOfDisciplineMembers',
                      },
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
