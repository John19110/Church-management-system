import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_providers.dart';
import '../models/custom_field_models.dart';
import '../providers/custom_field_providers.dart';
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
  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final canManage = role == 'admin' || role == 'superadmin';

    if (!canManage) {
      return Scaffold(
        appBar: AppBar(title: const Text('Custom fields')),
        body: const Center(child: Text('Not authorized')),
      );
    }

    final defsAsync = ref.watch(
      customFieldDefinitionsProvider(widget.entityName),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.entityName} custom fields'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await context.push<bool>(
            '/custom-fields/${widget.entityName}/new',
          );
          if (created == true) {
            ref.invalidate(customFieldDefinitionsProvider(widget.entityName));
          }
        },
        child: const Icon(Icons.add),
      ),
      body: defsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (defs) {
          if (defs.isEmpty) {
            return const Center(child: Text('No custom fields yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(customFieldDefinitionsProvider(widget.entityName));
            },
            child: ListView.builder(
              itemCount: defs.length,
              itemBuilder: (_, i) {
                final def = defs[i];
                return ListTile(
                  title: Text(def.displayName),
                  subtitle: Text('${def.name} · ${def.dataType.name}'),
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
                      ref.invalidate(
                        customFieldDefinitionsProvider(widget.entityName),
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
  }

  Future<void> _confirmDeactivate(CustomFieldDefinitionReadDto def) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Deactivate field',
      content:
          'Deactivate "${def.displayName}"? Existing values are preserved.',
      confirmText: 'Deactivate',
      confirmColor: Colors.orange,
    );
    if (ok != true) return;

    await ref.read(customFieldRepositoryProvider).deactivateDefinition(def.id);
    ref.invalidate(customFieldDefinitionsProvider(widget.entityName));
    if (mounted) {
      showSuccessSnackbar(context, 'Field deactivated');
    }
  }
}
