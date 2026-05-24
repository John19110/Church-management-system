import 'dart:convert';

import '../models/unified_form_models.dart';

class UnifiedFormValidator {
  static String? validate(UnifiedFieldDefinitionDto field, String? rawValue) {
    final empty = rawValue == null || rawValue.trim().isEmpty;
    if (empty) {
      return field.isRequired ? '${field.displayName} is required' : null;
    }

    final value = rawValue!.trim();

    if (field.validationRegex != null && field.validationRegex!.isNotEmpty) {
      if (!RegExp(field.validationRegex!).hasMatch(value)) {
        return '${field.displayName} does not match the required format';
      }
    }

    switch (field.dataType) {
      case UnifiedFieldDataType.number:
        if (int.tryParse(value) == null) {
          return '${field.displayName} must be a whole number';
        }
        break;
      case UnifiedFieldDataType.decimal:
        if (double.tryParse(value) == null) {
          return '${field.displayName} must be a number';
        }
        break;
      case UnifiedFieldDataType.date:
      case UnifiedFieldDataType.dateTime:
        if (DateTime.tryParse(value) == null) {
          return '${field.displayName} must be a valid date';
        }
        break;
      case UnifiedFieldDataType.json:
        try {
          jsonDecode(value);
        } catch (_) {
          return '${field.displayName} must be valid JSON';
        }
        break;
      case UnifiedFieldDataType.singleSelect:
        final allowed = field.options.map((o) => o.value).toSet();
        if (!allowed.contains(value)) {
          return 'Select a valid option for ${field.displayName}';
        }
        break;
      case UnifiedFieldDataType.multiSelect:
        break;
      default:
        break;
    }

    return null;
  }
}
