import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/custom_field_models.dart';
import '../providers/custom_field_providers.dart';

/// Read-only detail section for entity screens.
class CustomFieldsDetailSection extends ConsumerWidget {
  final String entityName;
  final int entityId;

  const CustomFieldsDetailSection({
    super.key,
    required this.entityName,
    required this.entityId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      entityCustomFieldsProvider((entity: entityName, id: entityId)),
    );

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final rows = <Widget>[];
        for (final def in data.definitions.where((d) => !d.isHidden)) {
          final value = data.valueForDefinition(def.id);
          if (value == null || value.isEmpty) continue;
          rows.add(
            ListTile(
              title: Text(def.displayName),
              subtitle: Text(_formatValue(def, value)),
            ),
          );
        }
        if (rows.isEmpty) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Additional fields',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...rows,
            ],
          ),
        );
      },
    );
  }

  String _formatValue(CustomFieldDefinitionReadDto def, String value) {
    if (def.dataType == CustomFieldDataType.boolean) {
      return value.toLowerCase() == 'true' ? 'Yes' : 'No';
    }
    if (def.dataType == CustomFieldDataType.multiSelect && value.startsWith('[')) {
      try {
        return value; // could decode JSON for nicer display
      } catch (_) {}
    }
    return value;
  }
}
