/// Custom field DTOs aligned with backend API contracts.

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.parse(value.toString());
}

class CustomFieldOptionDto {
  final int? id;
  final String value;
  final String displayText;
  final int sortOrder;

  const CustomFieldOptionDto({
    this.id,
    required this.value,
    required this.displayText,
    this.sortOrder = 0,
  });

  factory CustomFieldOptionDto.fromJson(Map<String, dynamic> json) {
    return CustomFieldOptionDto(
      id: json['id'] == null ? null : _readInt(json['id']),
      value: json['value'] as String? ?? '',
      displayText: json['displayText'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'value': value,
        'displayText': displayText,
        'sortOrder': sortOrder,
      };
}

enum CustomFieldDataType {
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

  static CustomFieldDataType fromString(String? raw) {
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

class CustomFieldDefinitionReadDto {
  final int id;
  final String name;
  final String displayName;
  final String? displayNameAr;
  final String? description;
  final String entityName;
  final CustomFieldDataType dataType;
  final bool isRequired;
  final bool isActive;
  final bool isReadOnly;
  final bool isHidden;
  final bool allowMultipleValues;
  final String? defaultValue;
  final String? placeholder;
  final String? validationRegex;
  final int sortOrder;
  final List<CustomFieldOptionDto> options;
  final bool isBuiltIn;
  final bool isSystemField;
  final bool isDeletable;
  final bool isPermanentDeletable;

  const CustomFieldDefinitionReadDto({
    required this.id,
    required this.name,
    required this.displayName,
    this.displayNameAr,
    this.description,
    required this.entityName,
    required this.dataType,
    this.isRequired = false,
    this.isActive = true,
    this.isReadOnly = false,
    this.isHidden = false,
    this.allowMultipleValues = false,
    this.defaultValue,
    this.placeholder,
    this.validationRegex,
    this.sortOrder = 0,
    this.options = const [],
    this.isBuiltIn = false,
    this.isSystemField = false,
    this.isDeletable = true,
    this.isPermanentDeletable = true,
  });

  factory CustomFieldDefinitionReadDto.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['options'] as List<dynamic>? ?? [];
    return CustomFieldDefinitionReadDto(
      id: _readInt(json['id']),
      name: json['name'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      displayNameAr: json['displayNameAr'] as String?,
      description: json['description'] as String?,
      entityName: json['entityName'] as String? ?? '',
      dataType: CustomFieldDataType.fromString(json['dataType'] as String?),
      isRequired: json['isRequired'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      isReadOnly: json['isReadOnly'] as bool? ?? false,
      isHidden: json['isHidden'] as bool? ?? false,
      allowMultipleValues: json['allowMultipleValues'] as bool? ?? false,
      defaultValue: json['defaultValue'] as String?,
      placeholder: json['placeholder'] as String?,
      validationRegex: json['validationRegex'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      options: optionsJson
          .map((e) => CustomFieldOptionDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      isBuiltIn: json['isBuiltIn'] as bool? ??
          json['isSystemField'] as bool? ??
          false,
      isSystemField: json['isSystemField'] as bool? ??
          json['isBuiltIn'] as bool? ??
          false,
      isDeletable: json['isDeletable'] as bool? ?? true,
      isPermanentDeletable: json['isPermanentDeletable'] as bool? ??
          json['isDeletable'] as bool? ??
          true,
    );
  }
}

class CustomFieldDefinitionCreateDto {
  /// Optional; server generates from [displayName] when omitted.
  final String? name;
  final String displayName;
  final String? displayNameAr;
  final String? description;
  final String entityName;
  final String dataType;
  final bool isRequired;
  final bool isReadOnly;
  final bool isHidden;
  final bool allowMultipleValues;
  final String? defaultValue;
  final String? placeholder;
  final String? validationRegex;
  final int sortOrder;
  final int? displayPosition;
  final List<CustomFieldOptionDto>? options;

  const CustomFieldDefinitionCreateDto({
    this.name,
    required this.displayName,
    this.displayNameAr,
    this.description,
    required this.entityName,
    required this.dataType,
    this.isRequired = false,
    this.isReadOnly = false,
    this.isHidden = false,
    this.allowMultipleValues = false,
    this.defaultValue,
    this.placeholder,
    this.validationRegex,
    this.sortOrder = 0,
    this.displayPosition,
    this.options,
  });

  Map<String, dynamic> toJson() => {
        if (name != null && name!.trim().isNotEmpty) 'name': name!.trim(),
        'displayName': displayName,
        if (displayNameAr != null && displayNameAr!.trim().isNotEmpty)
          'displayNameAr': displayNameAr!.trim(),
        if (description != null) 'description': description,
        'entityName': entityName,
        'dataType': dataType,
        'isRequired': isRequired,
        'isReadOnly': isReadOnly,
        'isHidden': isHidden,
        'allowMultipleValues': allowMultipleValues,
        if (defaultValue != null) 'defaultValue': defaultValue,
        if (placeholder != null) 'placeholder': placeholder,
        if (validationRegex != null) 'validationRegex': validationRegex,
        if (displayPosition != null) 'displayPosition': displayPosition,
        if (options != null) 'options': options!.map((o) => o.toJson()).toList(),
      };
}

class CustomFieldDefinitionUpdateDto {
  final String displayName;
  final String? displayNameAr;
  final String? dataType;
  final bool? isRequired;
  final bool? isActive;
  final bool? isReadOnly;
  final bool? isHidden;
  final int? sortOrder;
  final int? displayPosition;
  final String? placeholder;
  final String? validationRegex;
  final List<CustomFieldOptionDto>? options;

  const CustomFieldDefinitionUpdateDto({
    required this.displayName,
    this.displayNameAr,
    this.dataType,
    this.isRequired,
    this.isActive,
    this.isReadOnly,
    this.isHidden,
    this.sortOrder,
    this.displayPosition,
    this.placeholder,
    this.validationRegex,
    this.options,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'displayName': displayName};
    if (displayNameAr != null) map['displayNameAr'] = displayNameAr;
    if (dataType != null) map['dataType'] = dataType;
    if (isRequired != null) map['isRequired'] = isRequired;
    if (isActive != null) map['isActive'] = isActive;
    if (isReadOnly != null) map['isReadOnly'] = isReadOnly;
    if (isHidden != null) map['isHidden'] = isHidden;
    if (sortOrder != null) map['sortOrder'] = sortOrder;
    if (displayPosition != null) map['displayPosition'] = displayPosition;
    if (placeholder != null) map['placeholder'] = placeholder;
    if (validationRegex != null) map['validationRegex'] = validationRegex;
    if (options != null) {
      map['options'] = options!.map((o) => o.toJson()).toList();
    }
    return map;
  }
}

class CustomFieldValueItemDto {
  final int customFieldDefinitionId;
  final String? value;

  const CustomFieldValueItemDto({
    required this.customFieldDefinitionId,
    this.value,
  });

  Map<String, dynamic> toJson() => {
        'customFieldDefinitionId': customFieldDefinitionId,
        'value': value,
      };
}

class CustomFieldValueReadDto {
  final int customFieldDefinitionId;
  final String name;
  final String displayName;
  final String? displayNameAr;
  final CustomFieldDataType dataType;
  final String? value;
  final bool isReadOnly;
  final bool isHidden;

  const CustomFieldValueReadDto({
    required this.customFieldDefinitionId,
    required this.name,
    required this.displayName,
    this.displayNameAr,
    required this.dataType,
    this.value,
    this.isReadOnly = false,
    this.isHidden = false,
  });

  factory CustomFieldValueReadDto.fromJson(Map<String, dynamic> json) {
    return CustomFieldValueReadDto(
      customFieldDefinitionId: json['customFieldDefinitionId'] as int,
      name: json['name'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      displayNameAr: json['displayNameAr'] as String?,
      dataType: CustomFieldDataType.fromString(json['dataType'] as String?),
      value: json['value'] as String?,
      isReadOnly: json['isReadOnly'] as bool? ?? false,
      isHidden: json['isHidden'] as bool? ?? false,
    );
  }
}

class EntityCustomFieldsReadDto {
  final String entityName;
  final int entityId;
  final List<CustomFieldDefinitionReadDto> definitions;
  final List<CustomFieldValueReadDto> values;

  const EntityCustomFieldsReadDto({
    required this.entityName,
    required this.entityId,
    this.definitions = const [],
    this.values = const [],
  });

  factory EntityCustomFieldsReadDto.fromJson(Map<String, dynamic> json) {
    final defs = json['definitions'] as List<dynamic>? ?? [];
    final vals = json['values'] as List<dynamic>? ?? [];
    return EntityCustomFieldsReadDto(
      entityName: json['entityName'] as String? ?? '',
      entityId: json['entityId'] as int,
      definitions: defs
          .map((e) =>
              CustomFieldDefinitionReadDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      values: vals
          .map((e) =>
              CustomFieldValueReadDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String? valueForDefinition(int definitionId) {
    for (final v in values) {
      if (v.customFieldDefinitionId == definitionId) return v.value;
    }
    return null;
  }
}

/// Supported entity names for custom fields.
class CustomFieldEntityNames {
  static const member = 'Member';
  static const classroom = 'Classroom';
  static const servant = 'Servant';
  static const meeting = 'Meeting';
  static const church = 'Church';

  static const all = [member, classroom, servant, meeting, church];
}

/// Maps enum to API string (PascalCase as returned by ASP.NET JSON enum converter).
String customFieldDataTypeToApi(CustomFieldDataType type) {
  switch (type) {
    case CustomFieldDataType.text:
      return 'Text';
    case CustomFieldDataType.longText:
      return 'LongText';
    case CustomFieldDataType.number:
      return 'Number';
    case CustomFieldDataType.decimal:
      return 'Decimal';
    case CustomFieldDataType.boolean:
      return 'Boolean';
    case CustomFieldDataType.date:
      return 'Date';
    case CustomFieldDataType.dateTime:
      return 'DateTime';
    case CustomFieldDataType.json:
      return 'Json';
    case CustomFieldDataType.singleSelect:
      return 'SingleSelect';
    case CustomFieldDataType.multiSelect:
      return 'MultiSelect';
    case CustomFieldDataType.unknown:
      return 'Text';
  }
}
