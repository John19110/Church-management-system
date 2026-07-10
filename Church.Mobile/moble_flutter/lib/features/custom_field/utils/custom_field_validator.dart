import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../models/custom_field_models.dart';
import 'field_display_label.dart';

/// Client-side validation mirroring backend rules.
class CustomFieldValidator {
  static String? validate(
    CustomFieldDefinitionReadDto field,
    String? rawValue, {
    AppLocalizations? l10n,
  }) {
    final loc = l10n ?? AppLocalizations.forLocale(const Locale('en'));
    final displayName = localizedFieldDisplayLabel(field, loc);

    final empty = rawValue == null || rawValue.trim().isEmpty;
    if (empty) {
      return field.isRequired ? loc.fieldIsRequired(displayName) : null;
    }

    final value = rawValue!.trim();

    if (field.validationRegex != null && field.validationRegex!.isNotEmpty) {
      final regex = RegExp(field.validationRegex!);
      if (!regex.hasMatch(value)) {
        return loc.fieldFormatInvalid(displayName);
      }
    }

    switch (field.dataType) {
      case CustomFieldDataType.number:
        if (int.tryParse(value) == null) {
          return loc.fieldMustBeWholeNumber(displayName);
        }
        break;
      case CustomFieldDataType.decimal:
        if (double.tryParse(value) == null) {
          return loc.fieldMustBeNumber(displayName);
        }
        break;
      case CustomFieldDataType.boolean:
        final lower = value.toLowerCase();
        if (!['true', 'false', '1', '0', 'yes', 'no'].contains(lower)) {
          return loc.fieldMustBeBoolean(displayName);
        }
        break;
      case CustomFieldDataType.date:
        if (DateTime.tryParse(value) == null) {
          return loc.fieldMustBeValidDate(displayName);
        }
        break;
      case CustomFieldDataType.dateTime:
        if (DateTime.tryParse(value) == null) {
          return loc.fieldMustBeValidDateTime(displayName);
        }
        break;
      case CustomFieldDataType.json:
        try {
          jsonDecode(value);
        } catch (_) {
          return loc.fieldMustBeValidJson(displayName);
        }
        break;
      case CustomFieldDataType.singleSelect:
        final allowed = field.options.map((o) => o.value).toSet();
        if (!allowed.contains(value)) {
          return loc.selectValidOptionFor(displayName);
        }
        break;
      case CustomFieldDataType.multiSelect:
        final selected = _parseMulti(value);
        final allowed = field.options.map((o) => o.value).toSet();
        if (selected.isEmpty) {
          return field.isRequired
              ? loc.fieldRequiresAtLeastOneOption(displayName)
              : null;
        }
        if (selected.any((s) => !allowed.contains(s))) {
          return loc.invalidSelectionFor(displayName);
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
