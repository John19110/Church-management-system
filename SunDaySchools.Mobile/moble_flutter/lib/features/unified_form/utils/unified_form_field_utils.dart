import 'package:flutter/material.dart';

import '../../../core/field_labels/system_field_labels.dart';
import '../../../core/l10n/app_localizations.dart';
import '../models/unified_form_models.dart';

/// Built-in photo field synced to legacy `imageUrl` column (shown via photo picker, not text field).
const String kUnifiedPhotoFieldKey = 'imageUrl';

const Set<String> kUnifiedPhotoFieldKeys = {kUnifiedPhotoFieldKey};

/// Visible fields for forms/detail, optionally excluding keys handled elsewhere (e.g. photo).
List<T> visibleUnifiedFields<T extends UnifiedFieldDefinitionDto>(
  List<T> fields, {
  Set<String> excludeFieldKeys = const {},
}) {
  return fields
      .where((f) => !f.isHidden && !excludeFieldKeys.contains(f.fieldKey))
      .toList()
    ..sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      return order != 0 ? order : a.displayName.compareTo(b.displayName);
    });
}

String? fieldValue(List<UnifiedFieldDto> fields, String fieldKey) {
  for (final f in fields) {
    if (f.fieldKey == fieldKey) return f.value;
  }
  return null;
}

String? photoUrlFromFields(List<UnifiedFieldDto> fields) =>
    fieldValue(fields, kUnifiedPhotoFieldKey)?.trim().isNotEmpty == true
        ? fieldValue(fields, kUnifiedPhotoFieldKey)!.trim()
        : null;

/// Display title from unified fields (built-in name keys first, then first non-empty value).
String unifiedDisplayTitle(
  String entityName,
  List<UnifiedFieldDto> fields, {
  AppLocalizations? l10n,
}) {
  final loc = l10n ?? AppLocalizations.forLocale(const Locale('en'));
  const titleKeysByEntity = <String, List<String>>{
    UnifiedEntityNames.member: ['name1', 'name2', 'name3'],
    UnifiedEntityNames.servant: ['name'],
    UnifiedEntityNames.classroom: ['name'],
    UnifiedEntityNames.meeting: ['name'],
    UnifiedEntityNames.church: ['name'],
  };

  final keys = titleKeysByEntity[entityName];
  if (keys != null) {
    final parts = <String>[];
    for (final key in keys) {
      final v = fieldValue(fields, key)?.trim();
      if (v != null && v.isNotEmpty) parts.add(v);
    }
    if (parts.isNotEmpty) return parts.join(' ');
  }

  for (final f in fields) {
    if (f.isHidden || kUnifiedPhotoFieldKeys.contains(f.fieldKey)) continue;
    final v = f.value?.trim();
    if (v != null && v.isNotEmpty) return v;
  }
  return loc.notAvailable;
}

String unifiedDetailInitial(
  String entityName,
  List<UnifiedFieldDto> fields, {
  AppLocalizations? l10n,
}) {
  final loc = l10n ?? AppLocalizations.forLocale(const Locale('en'));
  final title = unifiedDisplayTitle(entityName, fields, l10n: loc);
  if (title != loc.notAvailable && title.isNotEmpty) {
    return title[0].toUpperCase();
  }
  return '?';
}

/// Localized label for built-in fields; custom fields keep API [displayName].
String unifiedFieldLabel(
  UnifiedFieldDefinitionDto field, {
  String? entityName,
  AppLocalizations? l10n,
}) {
  final loc = l10n ?? AppLocalizations.forLocale(const Locale('en'));
  if (entityName != null) {
    final localized = systemFieldLabel(loc, entityName, field.fieldKey);
    if (localized != null && localized.isNotEmpty) return localized;
  }
  return field.displayName;
}

/// Localized placeholder for built-in fields when the API sends English.
String? unifiedFieldPlaceholder(
  UnifiedFieldDefinitionDto field, {
  String? entityName,
  AppLocalizations? l10n,
}) {
  final loc = l10n ?? AppLocalizations.forLocale(const Locale('en'));
  if (entityName != null) {
    final localized = systemFieldPlaceholder(loc, entityName, field.fieldKey);
    if (localized != null && localized.isNotEmpty) return localized;
  }
  return field.placeholder;
}
