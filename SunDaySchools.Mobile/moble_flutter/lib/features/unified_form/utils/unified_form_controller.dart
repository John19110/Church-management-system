import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/unified_form_models.dart';
import '../utils/unified_form_validator.dart';

/// Holds editable values for a unified form (built-in + custom, same storage).
class UnifiedFormController {
  final Map<String, TextEditingController> _text = {};
  final Map<String, bool> _bools = {};
  final Map<String, List<String>> _multi = {};

  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
  }

  void initializeFromFields(List<UnifiedFieldDefinitionDto> fields, {List<UnifiedFieldDto>? withValues}) {
    final valueMap = <String, String?>{};
    if (withValues != null) {
      for (final f in withValues) {
        valueMap[f.fieldKey] = f.value;
      }
    }

    for (final field in fields.where((f) => !f.isHidden)) {
      final initial = valueMap[field.fieldKey] ?? field.defaultValue ?? '';

      if (field.dataType == UnifiedFieldDataType.boolean) {
        _bools[field.fieldKey] = _parseBool(initial);
      } else if (field.dataType == UnifiedFieldDataType.multiSelect) {
        _multi[field.fieldKey] = _parseMulti(initial);
        _text.putIfAbsent(field.fieldKey, TextEditingController.new);
      } else {
        _text.putIfAbsent(field.fieldKey, () => TextEditingController(text: initial));
      }
    }
  }

  TextEditingController controllerFor(String fieldKey) =>
      _text.putIfAbsent(fieldKey, TextEditingController.new);

  bool boolFor(String fieldKey) => _bools[fieldKey] ?? false;

  void setBool(String fieldKey, bool value) => _bools[fieldKey] = value;

  List<String> multiFor(String fieldKey) => _multi[fieldKey] ?? [];

  void setMulti(String fieldKey, List<String> values) => _multi[fieldKey] = values;

  String? valueFor(UnifiedFieldDefinitionDto field) {
    if (field.isReadOnly && field.fieldKey == 'imageUrl') {
      return _text[field.fieldKey]?.text;
    }
    switch (field.dataType) {
      case UnifiedFieldDataType.boolean:
        return boolFor(field.fieldKey) ? 'true' : 'false';
      case UnifiedFieldDataType.multiSelect:
        final selected = multiFor(field.fieldKey);
        return selected.isEmpty ? null : jsonEncode(selected);
      default:
        final text = _text[field.fieldKey]?.text.trim();
        return text == null || text.isEmpty ? null : text;
    }
  }

  SaveEntityFormDto buildSavePayload(List<UnifiedFieldDefinitionDto> fields) {
    final items = <UnifiedFieldValueDto>[];
    for (final field in fields) {
      if (field.isHidden || field.isReadOnly) continue;
      if (field.fieldKey == 'imageUrl') continue;
      items.add(UnifiedFieldValueDto(
        fieldKey: field.fieldKey,
        value: valueFor(field),
      ));
    }
    return SaveEntityFormDto(fields: items);
  }

  String? validate(UnifiedFieldDefinitionDto field) =>
      UnifiedFormValidator.validate(field, valueFor(field));

  static bool _parseBool(String? raw) {
    if (raw == null) return false;
    return raw.toLowerCase() == 'true' || raw == '1' || raw.toLowerCase() == 'yes';
  }

  static List<String> _parseMulti(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    if (raw.startsWith('[')) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        return list.map((e) => e.toString()).toList();
      } catch (_) {
        return [];
      }
    }
    return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }
}
