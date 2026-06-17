import '../models/custom_field_models.dart';
import '../../unified_form/models/unified_form_models.dart';

CustomFieldDataType unifiedDataTypeToCustom(UnifiedFieldDataType type) {
  switch (type) {
    case UnifiedFieldDataType.text:
      return CustomFieldDataType.text;
    case UnifiedFieldDataType.longText:
      return CustomFieldDataType.longText;
    case UnifiedFieldDataType.number:
      return CustomFieldDataType.number;
    case UnifiedFieldDataType.decimal:
      return CustomFieldDataType.decimal;
    case UnifiedFieldDataType.boolean:
      return CustomFieldDataType.boolean;
    case UnifiedFieldDataType.date:
      return CustomFieldDataType.date;
    case UnifiedFieldDataType.dateTime:
      return CustomFieldDataType.dateTime;
    case UnifiedFieldDataType.json:
      return CustomFieldDataType.json;
    case UnifiedFieldDataType.singleSelect:
      return CustomFieldDataType.singleSelect;
    case UnifiedFieldDataType.multiSelect:
      return CustomFieldDataType.multiSelect;
    case UnifiedFieldDataType.unknown:
      return CustomFieldDataType.unknown;
  }
}

CustomFieldDefinitionReadDto customFieldFromUnifiedField(
  UnifiedFieldDefinitionDto field,
  String entityName,
) {
  return CustomFieldDefinitionReadDto(
    id: field.customFieldDefinitionId ?? 0,
    name: field.fieldKey,
    displayName: field.displayName,
    description: field.description,
    entityName: entityName,
    dataType: unifiedDataTypeToCustom(field.dataType),
    isRequired: field.isRequired,
    isActive: true,
    isReadOnly: field.isReadOnly,
    isHidden: field.isHidden,
    sortOrder: field.sortOrder,
    placeholder: field.placeholder,
    validationRegex: field.validationRegex,
    isBuiltIn: field.isBuiltIn,
    isSystemField: field.isBuiltIn,
    isDeletable: !field.isBuiltIn,
  );
}

/// Merges [formSchema] system/custom fields into API definitions when the
/// definitions endpoint returns no built-in rows (older or mis-provisioned API).
List<CustomFieldDefinitionReadDto> mergeDefinitionsWithFormSchema(
  List<CustomFieldDefinitionReadDto> fromApi,
  EntityFormSchemaDto formSchema,
) {
  final entityName = formSchema.entityName;
  final byName = {
    for (final d in fromApi) d.name.toLowerCase(): d,
  };

  final merged = <CustomFieldDefinitionReadDto>[];

  for (final field in formSchema.fields) {
    final key = field.fieldKey.toLowerCase();
    final existing = byName.remove(key);
    if (existing != null) {
      merged.add(existing);
    } else {
      merged.add(customFieldFromUnifiedField(field, entityName));
    }
  }

  merged.addAll(byName.values);

  merged.sort((a, b) {
    final order = a.sortOrder.compareTo(b.sortOrder);
    return order != 0 ? order : a.displayName.compareTo(b.displayName);
  });

  return merged;
}

bool definitionsIncludeSystemFields(List<CustomFieldDefinitionReadDto> defs) =>
    defs.any((d) => d.isBuiltIn || d.isSystemField);
