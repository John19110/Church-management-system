import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/unified_form_models.dart';
import '../utils/unified_form_controller.dart';
import 'unified_form_field_widget.dart';

/// Single form renderer: iterates one field list (built-in + custom).
class UnifiedEntityForm extends ConsumerStatefulWidget {
  final List<UnifiedFieldDefinitionDto> fields;
  final UnifiedFormController controller;
  final bool readOnly;
  final List<Widget>? leading;
  final List<Widget>? trailing;

  const UnifiedEntityForm({
    super.key,
    required this.fields,
    required this.controller,
    this.readOnly = false,
    this.leading,
    this.trailing,
  });

  @override
  ConsumerState<UnifiedEntityForm> createState() => _UnifiedEntityFormState();
}

class _UnifiedEntityFormState extends ConsumerState<UnifiedEntityForm> {
  @override
  Widget build(BuildContext context) {
    final visible = widget.fields.where((f) => !f.isHidden).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

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
  final List<UnifiedFieldDto> fields;

  const UnifiedEntityDetailFields({super.key, required this.fields});

  @override
  Widget build(BuildContext context) {
    final visible = fields
        .where((f) => !f.isHidden && (f.value?.isNotEmpty ?? false))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (visible.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Details', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...visible.map(
              (f) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(f.displayName),
                subtitle: Text(_formatValue(f)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue(UnifiedFieldDto f) {
    if (f.dataType == UnifiedFieldDataType.boolean) {
      return f.value?.toLowerCase() == 'true' ? 'Yes' : 'No';
    }
    return f.value ?? '';
  }
}
