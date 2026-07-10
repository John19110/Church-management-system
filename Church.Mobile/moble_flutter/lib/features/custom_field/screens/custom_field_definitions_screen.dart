import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_palette.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../models/custom_field_models.dart';
import '../providers/custom_field_cache_providers.dart';
import '../providers/custom_field_providers.dart';
import '../utils/field_display_label.dart';
import '../utils/field_position_utils.dart';
import '../widgets/field_definition_card.dart';
import '../../../shared/widgets/common_widgets.dart';

/// Admin/SuperAdmin screen to list and manage system + custom field definitions.
class CustomFieldDefinitionsScreen extends ConsumerStatefulWidget {
  final String entityName;

  const CustomFieldDefinitionsScreen({super.key, required this.entityName});

  @override
  ConsumerState<CustomFieldDefinitionsScreen> createState() =>
      _CustomFieldDefinitionsScreenState();
}

class _CustomFieldDefinitionsScreenState
    extends ConsumerState<CustomFieldDefinitionsScreen> {
  Future<void> _reloadDefinitions(CustomFieldDefinitionsQuery query) async {
    refreshEntityFormsAfterDefinitionChange(ref, widget.entityName);
    await ref.read(customFieldDefinitionsProvider(query).future);
  }

  Future<void> _openAddField() async {
    final created = await context.push<bool>(
      '/custom-fields/${widget.entityName}/new',
    );
    if (created == true) {
      refreshEntityFormsAfterDefinitionChange(ref, widget.entityName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final roleAsync = ref.watch(currentUserRoleProvider);

    return roleAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.customFields)),
        body: const LoadingWidget(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.customFields)),
        body: AppErrorWidget(message: e.toString()),
      ),
      data: (role) {
        if (!AuthRoleUtils.canManageCustomFields(role)) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.customFields)),
            body: Center(child: Text(l10n.notAuthorized)),
          );
        }

        final defsQuery = (
          entityName: widget.entityName,
          includeInactive: true,
        );
        final defsAsync = ref.watch(customFieldDefinitionsProvider(defsQuery));

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.customFieldsForEntity(widget.entityName)),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: l10n.createField,
                onPressed: _openAddField,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openAddField,
            icon: const Icon(Icons.add),
            label: Text(l10n.createField),
          ),
          body: defsAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => AppErrorWidget(
              message: userFriendlyMessage(e, l10n),
              onRetry: () =>
                  ref.invalidate(customFieldDefinitionsProvider(defsQuery)),
            ),
            data: (defs) {
              final ordered = sortedActiveProvisionedFields(defs, l10n: l10n);
              final inactive = defs.where((d) => !d.isActive && d.id > 0).toList()
                ..sort((a, b) => compareFieldDefinitionLabels(a, b, l10n));

              if (ordered.isEmpty && inactive.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => _reloadDefinitions(defsQuery),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        l10n.customFieldsAdminDescription,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          l10n.noFieldsConfigured,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _openAddField,
                        icon: const Icon(Icons.add),
                        label: Text(l10n.createField),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => _reloadDefinitions(defsQuery),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 88),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        l10n.customFieldsAdminDescription,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                    if (ordered.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text(
                          l10n.fieldActive,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      ...ordered.map((def) => _fieldCard(def)),
                    ],
                    if (inactive.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                        child: Text(
                          l10n.fieldInactive,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      ...inactive.map(
                        (def) => FieldDefinitionCard(
                          definition: def,
                          onTap: () => _openEdit(def),
                          onReactivate: () => _confirmReactivate(def),
                          onDeletePermanently: def.isDeletable
                              ? () => _confirmDeletePermanently(def)
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _fieldCard(CustomFieldDefinitionReadDto def) {
    return FieldDefinitionCard(
      definition: def,
      onTap: () => _openEdit(def),
      onDeactivate:
          def.isDeletable ? () => _confirmDeactivate(def) : null,
      onDeletePermanently: def.isDeletable
          ? () => _confirmDeletePermanently(def)
          : null,
    );
  }

  Future<void> _openEdit(CustomFieldDefinitionReadDto def) async {
    final updated = await context.push<bool>(
      '/custom-fields/${widget.entityName}/edit/${def.id}',
      extra: def,
    );
    if (updated == true) {
      refreshEntityFormsAfterDefinitionChange(ref, widget.entityName);
    }
  }

  Future<void> _confirmDeactivate(CustomFieldDefinitionReadDto def) async {
    final l10n = AppLocalizations.of(context);
    if (!def.isDeletable) {
      showErrorSnackbar(context, l10n.systemFieldCannotDeactivate);
      return;
    }

    final ok = await showConfirmDialog(
      context,
      title: l10n.deactivateField,
      content: l10n.deactivateFieldConfirm(
        localizedFieldDisplayLabel(def, l10n),
      ),
      confirmText: l10n.deactivate,
      confirmColor: context.palette.warning,
    );
    if (ok != true) return;

    try {
      await ref.read(customFieldRepositoryProvider).deactivateDefinition(def.id);
      refreshEntityFormsAfterDefinitionChange(ref, widget.entityName);
      if (mounted) {
        showSuccessSnackbar(context, l10n.fieldDeactivated);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, userFriendlyMessage(e, l10n));
      }
    }
  }

  Future<void> _confirmReactivate(CustomFieldDefinitionReadDto def) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.reactivateField,
      content: l10n.reactivateFieldConfirm(
        localizedFieldDisplayLabel(def, l10n),
      ),
      confirmText: l10n.reactivate,
    );
    if (ok != true) return;

    try {
      await ref.read(customFieldRepositoryProvider).activateDefinition(def.id);
      refreshEntityFormsAfterDefinitionChange(ref, widget.entityName);
      if (mounted) {
        showSuccessSnackbar(context, l10n.fieldActivated);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, userFriendlyMessage(e, l10n));
      }
    }
  }

  Future<void> _confirmDeletePermanently(CustomFieldDefinitionReadDto def) async {
    final l10n = AppLocalizations.of(context);
    if (!def.isDeletable) {
      showErrorSnackbar(context, l10n.systemFieldCannotDelete);
      return;
    }

    final ok = await showConfirmDialog(
      context,
      title: l10n.deleteFieldPermanently,
      content: l10n.deleteFieldPermanentlyConfirm(
        localizedFieldDisplayLabel(def, l10n),
      ),
      confirmText: l10n.deletePermanently,
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (ok != true) return;

    try {
      await ref
          .read(customFieldRepositoryProvider)
          .deleteDefinitionPermanently(def.id);
      refreshEntityFormsAfterDefinitionChange(ref, widget.entityName);
      if (mounted) {
        showSuccessSnackbar(context, l10n.fieldDeletedPermanently);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, userFriendlyMessage(e, l10n));
      }
    }
  }
}
