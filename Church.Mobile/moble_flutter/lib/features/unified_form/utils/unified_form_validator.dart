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
        if (field.lookupEndpoint != null && field.lookupEndpoint!.isNotEmpty) {
          // Options are loaded from the API at render time, not in field.options.
          final id = int.tryParse(value);
          if (id == null || id <= 0) {
            return loc.selectValidOptionFor(displayName);
          }
          break;
        }
        final allowed = field.options.map((o) => o.value).toSet();
        if (!allowed.contains(value)) {
          return loc.selectValidOptionFor(displayName);
        }
        break;
      case UnifiedFieldDataType.multiSelect:
        if (field.lookupEndpoint != null && field.lookupEndpoint!.isNotEmpty) {
          final ids = _parseMultiIds(value);
          if (ids.isEmpty) {
            return field.isRequired ? loc.fieldIsRequired(displayName) : null;
          }
          if (ids.any((id) => id <= 0)) {
            return loc.selectValidOptionFor(displayName);
          }
          break;
        }
        break;
      default:
        break;
    }

    return null;
  }

  static List<int> _parseMultiIds(String raw) {
    if (raw.startsWith('[')) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((id) => id > 0)
            .toList();
      } catch (_) {
        return const [];
      }
    }
    return raw
        .split(',')
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .where((id) => id > 0)
        .toList();
  }
}
