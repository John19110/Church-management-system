import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../models/custom_field_models.dart';
import '../providers/custom_field_cache_providers.dart';
import '../providers/custom_field_providers.dart';
import '../utils/custom_field_l10n.dart';
import '../../../shared/widgets/common_widgets.dart';

/// Admin/SuperAdmin screen to list and manage custom field definitions.
class CustomFieldDefinitionsScreen extends ConsumerStatefulWidget {
  final String entityName;

  const CustomFieldDefinitionsScreen({super.key, required this.entityName});

  @override
  ConsumerState<CustomFieldDefinitionsScreen> createState() =>
      _CustomFieldDefinitionsScreenState();
}

class _CustomFieldDefinitionsScreenState
    extends ConsumerState<CustomFieldDefinitionsScreen> {
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

        final defsAsync = ref.watch(
          customFieldDefinitionsProvider(widget.entityName),
        );

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
            error: (e, _) => AppErrorWidget(message: e.toString()),
            data: (defs) {
              if (defs.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async {
                    refreshEntityFormsAfterDefinitionChange(
                      ref,
                      widget.entityName,
                    );
                  },
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
                          l10n.noCustomFieldsYet,
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
                onRefresh: () async {
                  refreshEntityFormsAfterDefinitionChange(
                    ref,
                    widget.entityName,
                  );
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: defs.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          l10n.customFieldsAdminDescription,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      );
                    }
                    final def = defs[i - 1];
                    return ListTile(
                      title: Text(def.displayName),
                      subtitle: Text(l10n.labelForDataType(def.dataType)),
                      trailing: Icon(
                        def.isActive ? Icons.check_circle : Icons.cancel,
                        color: def.isActive ? Colors.green : Colors.grey,
                      ),
                      onTap: () async {
                        final updated = await context.push<bool>(
                          '/custom-fields/${widget.entityName}/edit/${def.id}',
                          extra: def,
                        );
                        if (updated == true) {
                          refreshEntityFormsAfterDefinitionChange(
                            ref,
                            widget.entityName,
                          );
                        }
                      },
                      onLongPress: () => _confirmDeactivate(def),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmDeactivate(CustomFieldDefinitionReadDto def) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.deactivateField,
      content: l10n.deactivateFieldConfirm(def.displayName),
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
