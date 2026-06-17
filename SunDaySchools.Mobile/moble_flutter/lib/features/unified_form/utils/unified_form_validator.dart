import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../models/unified_form_models.dart';
import 'unified_form_field_utils.dart';

class UnifiedFormValidator {
  static String? validate(
    UnifiedFieldDefinitionDto field,
    String? rawValue, {
    AppLocalizations? l10n,
    String? entityName,
  }) {
    final loc = l10n ?? AppLocalizations.forLocale(const Locale('en'));
    final displayName = unifiedFieldLabel(
      field,
      entityName: entityName,
      l10n: loc,
    );

    final empty = rawValue == null || rawValue.trim().isEmpty;
    if (empty) {
      return field.isRequired ? loc.fieldIsRequired(displayName) : null;
    }

    final value = rawValue!.trim();

    if (field.validationRegex != null && field.validationRegex!.isNotEmpty) {
      if (!RegExp(field.validationRegex!).hasMatch(value)) {
        return loc.fieldFormatInvalid(displayName);
      }
    }

    switch (field.dataType) {
      case UnifiedFieldDataType.number:
        if (int.tryParse(value) == null) {
          return loc.fieldMustBeWholeNumber(displayName);
        }
        break;
      case UnifiedFieldDataType.decimal:
        if (double.tryParse(value) == null) {
          return loc.fieldMustBeNumber(displayName);
        }
        break;
      case UnifiedFieldDataType.date:
      case UnifiedFieldDataType.dateTime:
        if (DateTime.tryParse(value) == null) {
          return loc.fieldMustBeValidDate(displayName);
        }
        break;
      case UnifiedFieldDataType.json:
        try {
          jsonDecode(value);
        } catch (_) {
          return loc.fieldMustBeValidJson(displayName);
        }
        break;
      case UnifiedFieldDataType.singleSelect:
        final allowed = field.options.map((o) => o.value).toSet();
        if (!allowed.contains(value)) {
          return loc.selectValidOptionFor(displayName);
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
