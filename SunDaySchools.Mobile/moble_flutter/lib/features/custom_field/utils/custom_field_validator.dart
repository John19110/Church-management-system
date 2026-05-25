import 'dart:convert';

import '../models/custom_field_models.dart';

/// Client-side validation mirroring backend rules.
class CustomFieldValidator {
  static String? validate(
    CustomFieldDefinitionReadDto field,
    String? rawValue,
  ) {
    final empty = rawValue == null || rawValue.trim().isEmpty;
    if (empty) {
      return field.isRequired ? '${field.displayName} is required' : null;
    }

    final value = rawValue!.trim();

    if (field.validationRegex != null && field.validationRegex!.isNotEmpty) {
      final regex = RegExp(field.validationRegex!);
      if (!regex.hasMatch(value)) {
        return '${field.displayName} does not match the required format';
      }
    }

    switch (field.dataType) {
      case CustomFieldDataType.number:
        if (int.tryParse(value) == null) {
          return '${field.displayName} must be a whole number';
        }
        break;
      case CustomFieldDataType.decimal:
        if (double.tryParse(value) == null) {
          return '${field.displayName} must be a number';
        }
        break;
      case CustomFieldDataType.boolean:
        final lower = value.toLowerCase();
        if (!['true', 'false', '1', '0', 'yes', 'no'].contains(lower)) {
          return '${field.displayName} must be true or false';
        }
        break;
      case CustomFieldDataType.date:
        if (DateTime.tryParse(value) == null) {
          return '${field.displayName} must be a valid date';
        }
        break;
      case CustomFieldDataType.dateTime:
        if (DateTime.tryParse(value) == null) {
          return '${field.displayName} must be a valid date/time';
        }
        break;
      case CustomFieldDataType.json:
        try {
          jsonDecode(value);
        } catch (_) {
          return '${field.displayName} must be valid JSON';
        }
        break;
      case CustomFieldDataType.singleSelect:
        final allowed = field.options.map((o) => o.value).toSet();
        if (!allowed.contains(value)) {
          return 'Select a valid option for ${field.displayName}';
        }
        break;
      case CustomFieldDataType.multiSelect:
        final selected = _parseMulti(value);
        final allowed = field.options.map((o) => o.value).toSet();
        if (selected.isEmpty) {
          return field.isRequired
              ? '${field.displayName} requires at least one option'
              : null;
        }
        if (selected.any((s) => !allowed.contains(s))) {
          return 'Invalid selection for ${field.displayName}';
        }
        break;
      default:
        break;
    }

    return null;
  }

  static List<String> _parseMulti(String raw) {
    if (raw.startsWith('[')) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded.map((e) => e.toString()).toList();
      } catch (_) {
        return [];
      }
    }
    return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }
}
