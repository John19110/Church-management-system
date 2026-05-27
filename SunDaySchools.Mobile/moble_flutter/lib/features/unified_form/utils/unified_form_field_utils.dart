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
String unifiedDisplayTitle(String entityName, List<UnifiedFieldDto> fields) {
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
  return '—';
}

String unifiedDetailInitial(String entityName, List<UnifiedFieldDto> fields) {
  final title = unifiedDisplayTitle(entityName, fields);
  if (title != '—' && title.isNotEmpty) return title[0].toUpperCase();
  return '?';
}
