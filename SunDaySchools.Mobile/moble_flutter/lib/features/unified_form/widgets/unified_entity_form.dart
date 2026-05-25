import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/unified_form_models.dart';
import '../utils/unified_form_controller.dart';
import '../utils/unified_form_field_utils.dart';
import 'entity_fields_empty_state.dart';
import 'unified_form_field_widget.dart';

/// Single form renderer: iterates one field list (built-in + custom).
class UnifiedEntityForm extends ConsumerStatefulWidget {
  final List<UnifiedFieldDefinitionDto> fields;
  final UnifiedFormController controller;
  final bool readOnly;
  final List<Widget>? leading;
  final List<Widget>? trailing;
  final String? entityName;
  final String? configurationHint;
  final bool canManageDefinitions;
  /// Keys rendered outside the form (e.g. photo picker for `imageUrl`).
  final Set<String> excludeFieldKeys;

  const UnifiedEntityForm({
    super.key,
    required this.fields,
    required this.controller,
    this.readOnly = false,
    this.leading,
    this.trailing,
    this.entityName,
    this.configurationHint,
    this.canManageDefinitions = false,
    this.excludeFieldKeys = kUnifiedPhotoFieldKeys,
  });

  @override
  ConsumerState<UnifiedEntityForm> createState() => _UnifiedEntityFormState();
}

class _UnifiedEntityFormState extends ConsumerState<UnifiedEntityForm> {
  @override
  Widget build(BuildContext context) {
    final visible = visibleUnifiedFields(
      widget.fields,
      excludeFieldKeys: widget.excludeFieldKeys,
    );

    if (visible.isEmpty && widget.entityName != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.leading != null) ...widget.leading!,
          EntityFieldsEmptyState(
            entityName: widget.entityName!,
            configurationHint: widget.configurationHint,
            canManageDefinitions: widget.canManageDefinitions,
          ),
          if (widget.trailing != null) ...widget.trailing!,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.leading != null) ...widget.leading!,
        ...visible.map(
          (field) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: UnifiedFormFieldWidget(
              field: field,
              controller: widget.controller,
              readOnly: widget.readOnly,
            ),
          ),
        ),
        if (widget.trailing != null) ...widget.trailing!,
      ],
    );
  }
}

/// Read-only detail rows from the same unified field list.
class UnifiedEntityDetailFields extends StatelessWidget {
  final List<UnifiedFieldDto> fields; // built-in + custom values from form-data API

  const UnifiedEntityDetailFields({super.key, required this.fields});

  @override
  Widget build(BuildContext context) {
    final visible = visibleUnifiedFields(
      fields,
      excludeFieldKeys: kUnifiedPhotoFieldKeys,
    );

    if (visible.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: visible
              .map(
                (f) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(f.displayName),
                  subtitle: Text(_formatValue(f, context)),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  String _formatValue(UnifiedFieldDto f, BuildContext context) {
    if (f.value == null || f.value!.trim().isEmpty) {
      return '—';
    }
    if (f.dataType == UnifiedFieldDataType.boolean) {
      return f.value!.toLowerCase() == 'true' ? 'Yes' : 'No';
    }
    return f.value!;
  }
}
