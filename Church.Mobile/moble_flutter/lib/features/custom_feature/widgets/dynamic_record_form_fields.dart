import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/endpoint_select_fields.dart';
import '../models/custom_feature_models.dart';
import '../utils/custom_feature_labels.dart';

class DynamicRecordFormFields extends StatefulWidget {
  final CustomEntityReadDto entity;
  final Map<String, dynamic> values;
  final void Function() onChanged;
  final List<CustomEntityRecordReadDto> referenceRecords;

  const DynamicRecordFormFields({
    super.key,
    required this.entity,
    required this.values,
    required this.onChanged,
    this.referenceRecords = const [],
  });

  @override
  State<DynamicRecordFormFields> createState() =>
      _DynamicRecordFormFieldsState();
}

class _DynamicRecordFormFieldsState extends State<DynamicRecordFormFields> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant DynamicRecordFormFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
  }

  void _syncControllers() {
    for (final field in widget.entity.fields.where((f) => f.showOnForm)) {
      if (field.fieldType == CustomEntityFieldType.boolean ||
          field.fieldType.isReference ||
          field.fieldType == CustomEntityFieldType.dropdown) {
        continue;
      }
      final existing = _controllers[field.name];
      final text = widget.values[field.name]?.toString() ?? '';
      if (existing == null) {
        _controllers[field.name] = TextEditingController(text: text);
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fields = widget.entity.fields.where((f) => f.showOnForm).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return Column(
      children: [
        for (final field in fields)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildField(field, l10n),
          ),
      ],
    );
  }

  Widget _buildField(CustomEntityFieldReadDto field, AppLocalizations l10n) {
    final label = fieldDisplayName(field, l10n);
    final value = widget.values[field.name];
    String? requiredValidator(String? v) =>
        field.isRequired && (v == null || v.trim().isEmpty)
            ? l10n.required
            : null;

    switch (field.fieldType) {
      case CustomEntityFieldType.boolean:
        return SwitchListTile(
          title: Text(label),
          value: value == true || value?.toString() == 'true',
          onChanged: (v) {
            widget.values[field.name] = v;
            widget.onChanged();
          },
        );
      case CustomEntityFieldType.dropdown:
        return DropdownButtonFormField<String>(
          value: value?.toString(),
          decoration: InputDecoration(labelText: label),
          items: field.options
              .map(
                (o) => DropdownMenuItem(
                  value: o.value,
                  child: Text(optionDisplayText(o, l10n)),
                ),
              )
              .toList(),
          onChanged: (v) {
            widget.values[field.name] = v;
            widget.onChanged();
          },
          validator: field.isRequired
              ? (v) => (v == null || v.isEmpty) ? l10n.required : null
              : null,
        );
      case CustomEntityFieldType.memberReference:
        return EndpointSelectDropdown(
          endpoint: AppConstants.membersSelectEndpoint,
          label: label,
          value: _asInt(value),
          onChanged: (v) {
            widget.values[field.name] = v;
            widget.onChanged();
          },
          validator: field.isRequired ? (v) => v == null ? l10n.required : null : null,
        );
      case CustomEntityFieldType.servantReference:
        return EndpointSelectDropdown(
          endpoint: AppConstants.servantsSelectEndpoint,
          label: label,
          value: _asInt(value),
          onChanged: (v) {
            widget.values[field.name] = v;
            widget.onChanged();
          },
          validator: field.isRequired ? (v) => v == null ? l10n.required : null : null,
        );
      case CustomEntityFieldType.entityReference:
        final records = widget.referenceRecords
            .where((r) => r.entityId == (field.targetEntityId ?? -1))
            .toList();
        return DropdownButtonFormField<int>(
          value: _asInt(value),
          decoration: InputDecoration(labelText: label),
          items: records
              .map(
                (record) => DropdownMenuItem(
                  value: record.id,
                  child: Text('#${record.id}'),
                ),
              )
              .toList(),
          onChanged: (v) {
            widget.values[field.name] = v;
            widget.onChanged();
          },
          validator: field.isRequired ? (v) => v == null ? l10n.required : null : null,
        );
      default:
        final controller = _controllers[field.name]!;
        return AppTextField(
          controller: controller,
          label: label,
          maxLines: field.fieldType == CustomEntityFieldType.longText ? 4 : 1,
          keyboardType: _keyboard(field.fieldType),
          onChanged: (v) {
            widget.values[field.name] = v;
            widget.onChanged();
          },
          validator: requiredValidator,
        );
    }
  }

  TextInputType _keyboard(CustomEntityFieldType type) {
    switch (type) {
      case CustomEntityFieldType.number:
      case CustomEntityFieldType.decimal:
        return TextInputType.number;
      case CustomEntityFieldType.email:
        return TextInputType.emailAddress;
      case CustomEntityFieldType.phone:
        return TextInputType.phone;
      case CustomEntityFieldType.url:
        return TextInputType.url;
      default:
        return TextInputType.text;
    }
  }

  int? _asInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }
}
