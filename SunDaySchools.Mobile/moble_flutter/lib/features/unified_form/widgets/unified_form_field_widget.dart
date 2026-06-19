import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/endpoint_select_fields.dart';
import '../models/unified_form_models.dart';
import '../utils/unified_form_controller.dart';
import '../utils/unified_form_field_utils.dart';
import '../utils/unified_form_validator.dart';

/// Renders any unified field (built-in or custom) from metadata.
class UnifiedFormFieldWidget extends StatelessWidget {
  final UnifiedFieldDefinitionDto field;
  final UnifiedFormController controller;
  final bool readOnly;
  final String? entityName;

  const UnifiedFormFieldWidget({
    super.key,
    required this.field,
    required this.controller,
    this.readOnly = false,
    this.entityName,
  });

  @override
  Widget build(BuildContext context) {
    if (field.isHidden) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final label = unifiedFieldLabel(field, entityName: entityName, l10n: l10n);
    final placeholder = unifiedFieldPlaceholder(
      field,
      entityName: entityName,
      l10n: l10n,
    );
    final effectiveReadOnly = readOnly || field.isReadOnly;
    final validator = (String? _) => UnifiedFormValidator.validate(
          field,
          controller.valueFor(field),
          l10n: l10n,
          entityName: entityName,
        );

    switch (field.dataType) {
      case UnifiedFieldDataType.boolean:
        return SwitchListTile(
          title: Text(label),
          subtitle: field.description != null ? Text(field.description!) : null,
          value: controller.boolFor(field.fieldKey),
          onChanged: effectiveReadOnly
              ? null
              : (v) => controller.setBool(field.fieldKey, v),
        );

      case UnifiedFieldDataType.singleSelect:
        if (field.lookupEndpoint != null && field.lookupEndpoint!.isNotEmpty) {
          final current = int.tryParse(
            controller.controllerFor(field.fieldKey).text,
          );
          return EndpointSelectDropdown(
            endpoint: field.lookupEndpoint!,
            label: label,
            hintText: placeholder,
            value: current,
            enabled: !effectiveReadOnly,
            onChanged: (v) => controller
                .controllerFor(field.fieldKey)
                .text = v?.toString() ?? '',
            validator: effectiveReadOnly
                ? null
                : (v) => validator(v?.toString()),
          );
        }
        return DropdownButtonFormField<String>(
          value: controller.controllerFor(field.fieldKey).text.isEmpty
              ? null
              : controller.controllerFor(field.fieldKey).text,
          decoration: InputDecoration(
            labelText: label,
            hintText: placeholder,
          ),
          items: field.options
              .map((o) => DropdownMenuItem(
                    value: o.value,
                    child: Text(o.displayText),
                  ))
              .toList(),
          onChanged: effectiveReadOnly
              ? null
              : (v) {
                  controller.controllerFor(field.fieldKey).text = v ?? '';
                },
          validator: (_) => validator(null),
        );

      case UnifiedFieldDataType.multiSelect:
        if (field.lookupEndpoint != null && field.lookupEndpoint!.isNotEmpty) {
          return FormField<List<String>>(
            initialValue: controller.multiFor(field.fieldKey),
            validator: effectiveReadOnly
                ? null
                : (_) => validator(controller.valueFor(field)),
            builder: (state) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EndpointMultiSelectField(
                  endpoint: field.lookupEndpoint!,
                  label: label,
                  hintText: placeholder,
                  selectedIds: controller.multiFor(field.fieldKey)
                      .map(int.tryParse)
                      .whereType<int>()
                      .toList(),
                  onChanged: effectiveReadOnly
                      ? (_) {}
                      : (ids) {
                          final next = ids.map((id) => id.toString()).toList();
                          controller.setMulti(field.fieldKey, next);
                          state.didChange(next);
                        },
                ),
                if (state.hasError)
                  Text(
                    state.errorText!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
              ],
            ),
          );
        }
        return FormField<List<String>>(
          initialValue: controller.multiFor(field.fieldKey),
          validator: (_) => validator(controller.valueFor(field)),
          builder: (state) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              Wrap(
                spacing: 8,
                children: field.options.map((opt) {
                  final selected = controller.multiFor(field.fieldKey).contains(opt.value);
                  return FilterChip(
                    label: Text(opt.displayText),
                    selected: selected,
                    onSelected: effectiveReadOnly
                        ? null
                        : (sel) {
                            final next = List<String>.from(
                              controller.multiFor(field.fieldKey),
                            );
                            if (sel) {
                              next.add(opt.value);
                            } else {
                              next.remove(opt.value);
                            }
                            controller.setMulti(field.fieldKey, next);
                            state.didChange(next);
                          },
                  );
                }).toList(),
              ),
              if (state.hasError)
                Text(
                  state.errorText!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        );

      case UnifiedFieldDataType.longText:
      case UnifiedFieldDataType.json:
        return AppTextField(
          controller: controller.controllerFor(field.fieldKey),
          label: label,
          hint: placeholder,
          maxLines: field.dataType == UnifiedFieldDataType.json ? 5 : 4,
          readOnly: effectiveReadOnly,
          validator: validator,
        );

      case UnifiedFieldDataType.number:
        return AppTextField(
          controller: controller.controllerFor(field.fieldKey),
          label: label,
          keyboardType: TextInputType.number,
          readOnly: effectiveReadOnly,
          validator: validator,
        );

      case UnifiedFieldDataType.decimal:
        return AppTextField(
          controller: controller.controllerFor(field.fieldKey),
          label: label,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          readOnly: effectiveReadOnly,
          validator: validator,
        );

      case UnifiedFieldDataType.date:
        return AppDateField(
          controller: controller.controllerFor(field.fieldKey),
          label: label,
          validator: validator,
        );

      case UnifiedFieldDataType.dateTime:
        return AppTextField(
          controller: controller.controllerFor(field.fieldKey),
          label: label,
          readOnly: true,
          onTap: effectiveReadOnly
              ? null
              : () => _pickDateTime(context, field.fieldKey),
          validator: validator,
        );

      default:
        if (field.fieldKey == 'imageUrl') {
          final url = controller.controllerFor(field.fieldKey).text;
          if (url.isEmpty) return const SizedBox.shrink();
          return ListTile(
            title: Text(label),
            subtitle: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
          );
        }
        return AppTextField(
          controller: controller.controllerFor(field.fieldKey),
          label: label,
          hint: placeholder,
          readOnly: effectiveReadOnly,
          validator: validator,
        );
    }
  }

  Future<void> _pickDateTime(BuildContext context, String fieldKey) async {
    final c = controller.controllerFor(fieldKey);
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(c.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.tryParse(c.text) ?? DateTime.now()),
    );
    if (time == null) return;
    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    c.text = combined.toUtc().toIso8601String();
  }
}
