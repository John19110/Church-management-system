import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../models/custom_field_models.dart';
import '../utils/custom_field_validator.dart';
import '../utils/field_display_label.dart';

/// Renders a single dynamic field based on its definition.
class DynamicCustomFieldWidget extends StatelessWidget {
  final CustomFieldDefinitionReadDto definition;
  final TextEditingController controller;
  final bool? boolValue;
  final ValueChanged<bool?>? onBoolChanged;
  final List<String> multiSelected;
  final ValueChanged<List<String>>? onMultiChanged;
  final bool readOnly;

  const DynamicCustomFieldWidget({
    super.key,
    required this.definition,
    required this.controller,
    this.boolValue,
    this.onBoolChanged,
    this.multiSelected = const [],
    this.onMultiChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (definition.isHidden) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final label = localizedFieldDisplayLabel(definition, l10n);
    final validator = (String? v) =>
        CustomFieldValidator.validate(definition, v, l10n: l10n);

    switch (definition.dataType) {
      case CustomFieldDataType.longText:
        return AppTextField(
          controller: controller,
          label: label,
          hint: definition.placeholder,
          maxLines: 4,
          readOnly: readOnly || definition.isReadOnly,
          validator: validator,
        );
      case CustomFieldDataType.number:
        return AppTextField(
          controller: controller,
          label: label,
          hint: definition.placeholder,
          keyboardType: TextInputType.number,
          readOnly: readOnly || definition.isReadOnly,
          validator: validator,
        );
      case CustomFieldDataType.decimal:
        return AppTextField(
          controller: controller,
          label: label,
          hint: definition.placeholder,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          readOnly: readOnly || definition.isReadOnly,
          validator: validator,
        );
      case CustomFieldDataType.boolean:
        return SwitchListTile(
          title: Text(label),
          subtitle: definition.description != null
              ? Text(definition.description!)
              : null,
          value: boolValue ?? false,
          onChanged: (readOnly || definition.isReadOnly)
              ? null
              : (v) => onBoolChanged?.call(v),
        );
      case CustomFieldDataType.date:
        return AppDateField(
          controller: controller,
          label: label,
          validator: validator,
        );
      case CustomFieldDataType.dateTime:
        return AppTextField(
          controller: controller,
          label: label,
          hint: definition.placeholder ?? l10n.isoDateTimeHint,
          readOnly: true,
          onTap: (readOnly || definition.isReadOnly)
              ? null
              : () => _pickDateTime(context),
          validator: validator,
        );
      case CustomFieldDataType.json:
        return AppTextField(
          controller: controller,
          label: label,
          hint: definition.placeholder ?? l10n.jsonExampleHint,
          maxLines: 5,
          readOnly: readOnly || definition.isReadOnly,
          validator: validator,
        );
      case CustomFieldDataType.singleSelect:
        final items = definition.options;
        return DropdownButtonFormField<String>(
          value: controller.text.isEmpty ? null : controller.text,
          decoration: InputDecoration(labelText: label),
          items: items
              .map((o) => DropdownMenuItem(
                    value: o.value,
                    child: Text(o.displayText),
                  ))
              .toList(),
          onChanged: (readOnly || definition.isReadOnly)
              ? null
              : (v) {
                  controller.text = v ?? '';
                },
          validator: (_) => CustomFieldValidator.validate(
            definition,
            controller.text.isEmpty ? null : controller.text,
            l10n: l10n,
          ),
        );
      case CustomFieldDataType.multiSelect:
        return FormField<List<String>>(
          initialValue: multiSelected,
          validator: (_) {
            final serialized = multiSelected.isEmpty
                ? null
                : jsonEncode(multiSelected);
            return CustomFieldValidator.validate(
              definition,
              serialized,
              l10n: l10n,
            );
          },
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleSmall),
                if (definition.description != null)
                  Text(definition.description!),
                Wrap(
                  spacing: 8,
                  children: definition.options.map((opt) {
                    final selected = multiSelected.contains(opt.value);
                    return FilterChip(
                      label: Text(opt.displayText),
                      selected: selected,
                      onSelected: (readOnly || definition.isReadOnly)
                          ? null
                          : (sel) {
                              final next = List<String>.from(multiSelected);
                              if (sel) {
                                next.add(opt.value);
                              } else {
                                next.remove(opt.value);
                              }
                              onMultiChanged?.call(next);
                              state.didChange(next);
                            },
                    );
                  }).toList(),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      default:
        return AppTextField(
          controller: controller,
          label: label,
          hint: definition.placeholder,
          readOnly: readOnly || definition.isReadOnly,
          validator: validator,
        );
    }
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateTime.tryParse(controller.text) ?? DateTime.now(),
      ),
    );
    if (time == null) return;

    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    controller.text = combined.toUtc().toIso8601String();
  }
}
