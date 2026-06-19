/// Unified form models — one list for built-in and custom fields.

enum UnifiedFieldDataType {
  text,
  longText,
  number,
  decimal,
  boolean,
  date,
  dateTime,
  json,
  singleSelect,
  multiSelect,
  unknown;

  static UnifiedFieldDataType fromString(String? raw) {
    if (raw == null) return unknown;
    switch (raw.toLowerCase()) {
      case 'text':
        return text;
      case 'longtext':
        return longText;
      case 'number':
        return number;
      case 'decimal':
        return decimal;
      case 'boolean':
        return boolean;
      case 'date':
        return date;
      case 'datetime':
        return dateTime;
      case 'json':
        return json;
      case 'singleselect':
        return singleSelect;
      case 'multiselect':
        return multiSelect;
      default:
        return unknown;
    }
  }
}

class UnifiedFieldOptionDto {
  final String value;
  final String displayText;
  final int sortOrder;

  const UnifiedFieldOptionDto({
    required this.value,
    required this.displayText,
    this.sortOrder = 0,
  });

  factory UnifiedFieldOptionDto.fromJson(Map<String, dynamic> json) {
    return UnifiedFieldOptionDto(
      value: json['value'] as String? ?? '',
      displayText: json['displayText'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

class UnifiedFieldDefinitionDto {
  final String fieldKey;
  final String displayName;
  final String? displayNameAr;
  final String? description;
  final UnifiedFieldDataType dataType;
  final bool isRequired;
  final bool isBuiltIn;
  final bool isReadOnly;
  final bool isHidden;
  final int sortOrder;
  final bool allowMultipleValues;
  final String? defaultValue;
  final String? placeholder;
  final String? validationRegex;
  final String? lookupEndpoint;
  final int? customFieldDefinitionId;
  final List<UnifiedFieldOptionDto> options;

  const UnifiedFieldDefinitionDto({
    required this.fieldKey,
    required this.displayName,
    this.displayNameAr,
    this.description,
    required this.dataType,
    this.isRequired = false,
    this.isBuiltIn = false,
    this.isReadOnly = false,
    this.isHidden = false,
    this.sortOrder = 0,
    this.allowMultipleValues = false,
    this.defaultValue,
    this.placeholder,
    this.validationRegex,
    this.lookupEndpoint,
    this.customFieldDefinitionId,
    this.options = const [],
  });

  factory UnifiedFieldDefinitionDto.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['options'] as List<dynamic>? ?? [];
    return UnifiedFieldDefinitionDto(
      fieldKey: json['fieldKey'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      displayNameAr: json['displayNameAr'] as String?,
      description: json['description'] as String?,
      dataType: UnifiedFieldDataType.fromString(json['dataType'] as String?),
      isRequired: json['isRequired'] as bool? ?? false,
      isBuiltIn: json['isBuiltIn'] as bool? ?? true,
      isReadOnly: json['isReadOnly'] as bool? ?? false,
      isHidden: json['isHidden'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
      allowMultipleValues: json['allowMultipleValues'] as bool? ?? false,
      defaultValue: json['defaultValue'] as String?,
      placeholder: json['placeholder'] as String?,
      validationRegex: json['validationRegex'] as String?,
      lookupEndpoint: json['lookupEndpoint'] as String?,
      customFieldDefinitionId: json['customFieldDefinitionId'] as int?,
      options: optionsJson
          .map((e) => UnifiedFieldOptionDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UnifiedFieldDto extends UnifiedFieldDefinitionDto {
  final String? value;

  const UnifiedFieldDto({
    required super.fieldKey,
    required super.displayName,
    super.displayNameAr,
    super.description,
    required super.dataType,
    super.isRequired,
    super.isBuiltIn,
    super.isReadOnly,
    super.isHidden,
    super.sortOrder,
    super.allowMultipleValues,
    super.defaultValue,
    super.placeholder,
    super.validationRegex,
    super.lookupEndpoint,
    super.customFieldDefinitionId,
    super.options,
    this.value,
  });

  factory UnifiedFieldDto.fromJson(Map<String, dynamic> json) {
    final def = UnifiedFieldDefinitionDto.fromJson(json);
    return UnifiedFieldDto(
      fieldKey: def.fieldKey,
      displayName: def.displayName,
      displayNameAr: def.displayNameAr,
      description: def.description,
      dataType: def.dataType,
      isRequired: def.isRequired,
      isBuiltIn: def.isBuiltIn,
      isReadOnly: def.isReadOnly,
      isHidden: def.isHidden,
      sortOrder: def.sortOrder,
      allowMultipleValues: def.allowMultipleValues,
      defaultValue: def.defaultValue,
      placeholder: def.placeholder,
      validationRegex: def.validationRegex,
      lookupEndpoint: def.lookupEndpoint,
      customFieldDefinitionId: def.customFieldDefinitionId,
      options: def.options,
      value: json['value'] as String?,
    );
  }
}

class EntityFormSchemaDto {
  final String entityName;
  final String formMode;
  final List<UnifiedFieldDefinitionDto> fields;
  final String? configurationHint;
  final List<String> recommendedSyncFieldKeys;

  const EntityFormSchemaDto({
    required this.entityName,
    required this.formMode,
    this.fields = const [],
    this.configurationHint,
    this.recommendedSyncFieldKeys = const [],
  });

  factory EntityFormSchemaDto.fromJson(Map<String, dynamic> json) {
    final list = json['fields'] as List<dynamic>? ?? [];
    final syncKeys = json['recommendedSyncFieldKeys'] as List<dynamic>? ?? [];
    return EntityFormSchemaDto(
      entityName: json['entityName'] as String? ?? '',
      formMode: json['formMode'] as String? ?? 'Edit',
      configurationHint: json['configurationHint'] as String?,
      recommendedSyncFieldKeys:
          syncKeys.map((e) => e.toString()).toList(),
      fields: list
          .map((e) =>
              UnifiedFieldDefinitionDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EntityFormDataDto {
  final String entityName;
  final int entityId;
  final List<UnifiedFieldDto> fields;

  const EntityFormDataDto({
    required this.entityName,
    required this.entityId,
    this.fields = const [],
  });

  factory EntityFormDataDto.fromJson(Map<String, dynamic> json) {
    final list = json['fields'] as List<dynamic>? ?? [];
    return EntityFormDataDto(
      entityName: json['entityName'] as String? ?? '',
      entityId: json['entityId'] as int,
      fields: list
          .map((e) => UnifiedFieldDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SaveEntityFormDto {
  final List<UnifiedFieldValueDto> fields;

  const SaveEntityFormDto({required this.fields});

  Map<String, dynamic> toJson() => {
        'fields': fields.map((f) => f.toJson()).toList(),
      };
}

class UnifiedFieldValueDto {
  final String fieldKey;
  final String? value;

  const UnifiedFieldValueDto({required this.fieldKey, this.value});

  Map<String, dynamic> toJson() => {
        'fieldKey': fieldKey,
        'value': value,
      };
}

/// Entity names aligned with backend CustomFieldEntityNames.
class UnifiedEntityNames {
  static const member = 'Member';
  static const classroom = 'Classroom';
  static const servant = 'Servant';
  static const meeting = 'Meeting';
  static const church = 'Church';
}
