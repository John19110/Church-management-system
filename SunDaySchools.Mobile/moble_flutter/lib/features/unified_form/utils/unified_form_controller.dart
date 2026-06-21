import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/unified_form_models.dart';
import '../utils/unified_form_validator.dart';

/// Holds editable values for a unified form (admin-defined custom fields).
class UnifiedFormController {
  final Map<String, TextEditingController> _text = {};
  final Map<String, bool> _bools = {};
  final Map<String, List<String>> _multi = {};

  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    _text.clear();
    _bools.clear();
    _multi.clear();
  }

  /// Rebuilds controllers when the field list changes (e.g. after admin adds attributes).
  void initializeFromFields(
    List<UnifiedFieldDefinitionDto> fields, {
    List<UnifiedFieldDto>? withValues,
  }) {
    final visible = fields.where((f) => !f.isHidden).toList();
    final valueMap = <String, String?>{};
    if (withValues != null) {
      for (final f in withValues) {
        valueMap[f.fieldKey] = f.value;
      }
    }

    final keys = visible.map((f) => f.fieldKey).toSet();

    for (final key in _text.keys.toList()) {
      if (!keys.contains(key)) {
        _text[key]!.dispose();
        _text.remove(key);
        _bools.remove(key);
        _multi.remove(key);
      }
    }

    for (final field in visible) {
      final initial = valueMap[field.fieldKey] ?? field.defaultValue ?? '';

      switch (field.dataType) {
        case UnifiedFieldDataType.boolean:
          _bools[field.fieldKey] = _parseBool(initial);
          break;
        case UnifiedFieldDataType.multiSelect:
          _multi[field.fieldKey] = _parseMulti(initial);
          if (_text.containsKey(field.fieldKey)) {
            _text[field.fieldKey]!.text = initial;
          } else {
            _text[field.fieldKey] = TextEditingController(text: initial);
          }
          break;
        default:
          if (_text.containsKey(field.fieldKey)) {
            _text[field.fieldKey]!.text = initial;
          } else {
            _text[field.fieldKey] = TextEditingController(text: initial);
          }
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
    switch (field.dataType) {
      case UnifiedFieldDataType.boolean:
        return boolFor(field.fieldKey) ? 'true' : 'false';
      case UnifiedFieldDataType.multiSelect:
        final selected = multiFor(field.fieldKey);
        if (selected.isEmpty) return null;
        final ids = selected
            .map((s) => int.tryParse(s))
            .whereType<int>()
            .where((id) => id > 0)
            .toList();
        if (ids.isEmpty) return null;
        return jsonEncode(ids);
      default:
        final text = _text[field.fieldKey]?.text.trim();
        return text == null || text.isEmpty ? null : text;
    }
  }

  SaveEntityFormDto buildSavePayload(List<UnifiedFieldDefinitionDto> fields) {
    final items = <UnifiedFieldValueDto>[];
    for (final field in fields) {
      if (field.isHidden || field.isReadOnly) continue;
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
