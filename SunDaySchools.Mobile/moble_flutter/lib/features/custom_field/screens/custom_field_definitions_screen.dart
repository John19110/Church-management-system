import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../models/custom_field_models.dart';
import '../providers/custom_field_cache_providers.dart';
import '../providers/custom_field_providers.dart';
import '../utils/field_display_label.dart';
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

  List<CustomFieldDefinitionReadDto> _sorted(
    Iterable<CustomFieldDefinitionReadDto> defs,
  ) {
    final list = defs.toList()
      ..sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        return order != 0 ? order : a.displayName.compareTo(b.displayName);
      });
    return list;
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
              final systemFields = _sorted(
                defs.where((d) => d.isBuiltIn || d.isSystemField),
              );
              final customFields = _sorted(
                defs.where((d) => !d.isBuiltIn && !d.isSystemField),
              );

              if (systemFields.isEmpty && customFields.isEmpty) {
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
                    if (systemFields.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text(
                          l10n.systemFieldsSection,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          l10n.systemFieldsSectionHint,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      ...systemFields.map(
                        (def) => FieldDefinitionCard(
                          definition: def,
                          onTap: () => _openEdit(def),
                          onLongPress: def.isDeletable
                              ? () => _confirmDeactivate(def)
                              : null,
                        ),
                      ),
                    ],
                    if (customFields.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                        child: Text(
                          l10n.customFieldsSection,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      ...customFields.map(
                        (def) => FieldDefinitionCard(
                          definition: def,
                          onTap: () => _openEdit(def),
                          onLongPress: () => _confirmDeactivate(def),
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
      confirmColor: Colors.orange,
    );
    if (ok != true) return;

    await ref.read(customFieldRepositoryProvider).deactivateDefinition(def.id);
    refreshEntityFormsAfterDefinitionChange(ref, widget.entityName);
    if (mounted) {
      showSuccessSnackbar(context, l10n.fieldDeactivated);
    }
  }
}
