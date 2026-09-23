int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.parse(value.toString());
}

bool _readBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}

class CustomFeatureOptionDto {
  final int? id;
  final String value;
  final String displayText;
  final String? displayTextAr;
  final int sortOrder;

  const CustomFeatureOptionDto({
    this.id,
    required this.value,
    required this.displayText,
    this.displayTextAr,
    this.sortOrder = 0,
  });

  factory CustomFeatureOptionDto.fromJson(Map<String, dynamic> json) {
    return CustomFeatureOptionDto(
      id: json['id'] == null ? null : _readInt(json['id']),
      value: json['value'] as String? ?? '',
      displayText: json['displayText'] as String? ?? '',
      displayTextAr: json['displayTextAr'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'value': value,
        'displayText': displayText,
        if (displayTextAr != null) 'displayTextAr': displayTextAr,
        'sortOrder': sortOrder,
      };
}

enum CustomEntityFieldType {
  text,
  longText,
  number,
  decimal,
  boolean,
  date,
  time,
  dateTime,
  phone,
  email,
  url,
  dropdown,
  multiSelect,
  memberReference,
  servantReference,
  entityReference,
  entityMultiReference,
  unknown;

  String get apiName {
    switch (this) {
      case CustomEntityFieldType.longText:
        return 'LongText';
      case CustomEntityFieldType.dateTime:
        return 'DateTime';
      case CustomEntityFieldType.multiSelect:
        return 'MultiSelect';
      case CustomEntityFieldType.memberReference:
        return 'MemberReference';
      case CustomEntityFieldType.servantReference:
        return 'ServantReference';
      case CustomEntityFieldType.entityReference:
        return 'EntityReference';
      case CustomEntityFieldType.entityMultiReference:
        return 'EntityMultiReference';
      case CustomEntityFieldType.unknown:
        return 'Text';
      default:
        final raw = name;
        return raw[0].toUpperCase() + raw.substring(1);
    }
  }

  bool get isSelect =>
      this == CustomEntityFieldType.dropdown ||
      this == CustomEntityFieldType.multiSelect;

  bool get isEntityRef =>
      this == CustomEntityFieldType.entityReference ||
      this == CustomEntityFieldType.entityMultiReference;

  bool get isCoreRef =>
      this == CustomEntityFieldType.memberReference ||
      this == CustomEntityFieldType.servantReference;

  bool get isReference => isEntityRef || isCoreRef;

  static CustomEntityFieldType fromString(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'text':
        return CustomEntityFieldType.text;
      case 'longtext':
        return CustomEntityFieldType.longText;
      case 'number':
        return CustomEntityFieldType.number;
      case 'decimal':
        return CustomEntityFieldType.decimal;
      case 'boolean':
        return CustomEntityFieldType.boolean;
      case 'date':
        return CustomEntityFieldType.date;
      case 'time':
        return CustomEntityFieldType.time;
      case 'datetime':
        return CustomEntityFieldType.dateTime;
      case 'phone':
        return CustomEntityFieldType.phone;
      case 'email':
        return CustomEntityFieldType.email;
      case 'url':
        return CustomEntityFieldType.url;
      case 'dropdown':
        return CustomEntityFieldType.dropdown;
      case 'multiselect':
        return CustomEntityFieldType.multiSelect;
      case 'memberreference':
        return CustomEntityFieldType.memberReference;
      case 'servantreference':
        return CustomEntityFieldType.servantReference;
      case 'entityreference':
        return CustomEntityFieldType.entityReference;
      case 'entitymultireference':
        return CustomEntityFieldType.entityMultiReference;
      default:
        return CustomEntityFieldType.unknown;
    }
  }

  static const createChoices = <CustomEntityFieldType>[
    CustomEntityFieldType.text,
    CustomEntityFieldType.longText,
    CustomEntityFieldType.number,
    CustomEntityFieldType.decimal,
    CustomEntityFieldType.boolean,
    CustomEntityFieldType.date,
    CustomEntityFieldType.time,
    CustomEntityFieldType.dateTime,
    CustomEntityFieldType.phone,
    CustomEntityFieldType.email,
    CustomEntityFieldType.url,
    CustomEntityFieldType.dropdown,
    CustomEntityFieldType.multiSelect,
    CustomEntityFieldType.memberReference,
    CustomEntityFieldType.servantReference,
    CustomEntityFieldType.entityReference,
    CustomEntityFieldType.entityMultiReference,
  ];
}

class CustomEntityPermissionDto {
  final String roleName;
  final bool canCreate;
  final bool canRead;
  final bool canUpdate;
  final bool canDelete;

  const CustomEntityPermissionDto({
    required this.roleName,
    required this.canCreate,
    required this.canRead,
    required this.canUpdate,
    required this.canDelete,
  });

  factory CustomEntityPermissionDto.fromJson(Map<String, dynamic> json) {
    return CustomEntityPermissionDto(
      roleName: json['roleName'] as String? ?? '',
      canCreate: _readBool(json['canCreate']),
      canRead: _readBool(json['canRead']),
      canUpdate: _readBool(json['canUpdate']),
      canDelete: _readBool(json['canDelete']),
    );
  }

  Map<String, dynamic> toJson() => {
        'roleName': roleName,
        'canCreate': canCreate,
        'canRead': canRead,
        'canUpdate': canUpdate,
        'canDelete': canDelete,
      };

  CustomEntityPermissionDto copyWith({
    bool? canCreate,
    bool? canRead,
    bool? canUpdate,
    bool? canDelete,
  }) {
    return CustomEntityPermissionDto(
      roleName: roleName,
      canCreate: canCreate ?? this.canCreate,
      canRead: canRead ?? this.canRead,
      canUpdate: canUpdate ?? this.canUpdate,
      canDelete: canDelete ?? this.canDelete,
    );
  }
}

class CustomEntityFieldReadDto {
  final int id;
  final int entityId;
  final String name;
  final String displayName;
  final String? displayNameAr;
  final CustomEntityFieldType fieldType;
  final bool isRequired;
  final bool isUnique;
  final bool isSearchable;
  final bool showOnList;
  final bool showOnForm;
  final bool showOnDetails;
  final int displayOrder;
  final String? placeholder;
  final String? validationRegex;
  final int? targetEntityId;
  final String coreReference;
  final List<CustomFeatureOptionDto> options;

  const CustomEntityFieldReadDto({
    required this.id,
    required this.entityId,
    required this.name,
    required this.displayName,
    this.displayNameAr,
    required this.fieldType,
    required this.isRequired,
    required this.isUnique,
    required this.isSearchable,
    required this.showOnList,
    required this.showOnForm,
    required this.showOnDetails,
    required this.displayOrder,
    this.placeholder,
    this.validationRegex,
    this.targetEntityId,
    this.coreReference = 'None',
    this.options = const [],
  });

  factory CustomEntityFieldReadDto.fromJson(Map<String, dynamic> json) {
    return CustomEntityFieldReadDto(
      id: _readInt(json['id']),
      entityId: _readInt(json['entityId']),
      name: json['name'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      displayNameAr: json['displayNameAr'] as String?,
      fieldType: CustomEntityFieldType.fromString(json['fieldType'] as String?),
      isRequired: _readBool(json['isRequired']),
      isUnique: _readBool(json['isUnique']),
      isSearchable: _readBool(json['isSearchable']),
      showOnList: _readBool(json['showOnList'], fallback: true),
      showOnForm: _readBool(json['showOnForm'], fallback: true),
      showOnDetails: _readBool(json['showOnDetails'], fallback: true),
      displayOrder: json['displayOrder'] as int? ?? 0,
      placeholder: json['placeholder'] as String?,
      validationRegex: json['validationRegex'] as String?,
      targetEntityId:
          json['targetEntityId'] == null ? null : _readInt(json['targetEntityId']),
      coreReference: json['coreReference'] as String? ?? 'None',
      options: (json['options'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CustomFeatureOptionDto.fromJson)
          .toList(),
    );
  }
}

class CustomEntityReadDto {
  final int id;
  final int featureId;
  final String name;
  final String displayName;
  final String? displayNameAr;
  final String pluralDisplayName;
  final String? pluralDisplayNameAr;
  final bool isActive;
  final int sortOrder;
  final List<CustomEntityFieldReadDto> fields;
  final List<CustomEntityPermissionDto> permissions;

  const CustomEntityReadDto({
    required this.id,
    required this.featureId,
    required this.name,
    required this.displayName,
    this.displayNameAr,
    required this.pluralDisplayName,
    this.pluralDisplayNameAr,
    required this.isActive,
    required this.sortOrder,
    this.fields = const [],
    this.permissions = const [],
  });

  factory CustomEntityReadDto.fromJson(Map<String, dynamic> json) {
    return CustomEntityReadDto(
      id: _readInt(json['id']),
      featureId: _readInt(json['featureId']),
      name: json['name'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      displayNameAr: json['displayNameAr'] as String?,
      pluralDisplayName: json['pluralDisplayName'] as String? ?? '',
      pluralDisplayNameAr: json['pluralDisplayNameAr'] as String?,
      isActive: _readBool(json['isActive'], fallback: true),
      sortOrder: json['sortOrder'] as int? ?? 0,
      fields: (json['fields'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CustomEntityFieldReadDto.fromJson)
          .toList(),
      permissions: (json['permissions'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CustomEntityPermissionDto.fromJson)
          .toList(),
    );
  }

  CustomEntityPermissionDto? permissionForRole(String? role) {
    if (role == null) return null;
    final normalized = role.toLowerCase();
    for (final permission in permissions) {
      if (permission.roleName.toLowerCase() == normalized) return permission;
    }
    return null;
  }
}

class CustomFeatureReadDto {
  final int id;
  final String name;
  final String displayName;
  final String? displayNameAr;
  final bool isActive;
  final int? meetingId;
  final DateTime? createdAt;
  final List<CustomEntityReadDto> entities;

  const CustomFeatureReadDto({
    required this.id,
    required this.name,
    required this.displayName,
    this.displayNameAr,
    required this.isActive,
    this.meetingId,
    this.createdAt,
    this.entities = const [],
  });

  factory CustomFeatureReadDto.fromJson(Map<String, dynamic> json) {
    return CustomFeatureReadDto(
      id: _readInt(json['id']),
      name: json['name'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      displayNameAr: json['displayNameAr'] as String?,
      isActive: _readBool(json['isActive'], fallback: true),
      meetingId: json['meetingId'] == null ? null : _readInt(json['meetingId']),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
      entities: (json['entities'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CustomEntityReadDto.fromJson)
          .toList(),
    );
  }
}

class CustomEntityRecordReadDto {
  final int id;
  final int entityId;
  final Map<String, dynamic> values;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomEntityRecordReadDto({
    required this.id,
    required this.entityId,
    required this.values,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomEntityRecordReadDto.fromJson(Map<String, dynamic> json) {
    return CustomEntityRecordReadDto(
      id: _readInt(json['id']),
      entityId: _readInt(json['entityId']),
      values: Map<String, dynamic>.from(json['values'] as Map? ?? const {}),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'].toString()),
    );
  }
}

class CustomEntityRecordPageDto {
  final List<CustomEntityRecordReadDto> items;
  final int total;
  final int page;
  final int pageSize;

  const CustomEntityRecordPageDto({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory CustomEntityRecordPageDto.fromJson(Map<String, dynamic> json) {
    return CustomEntityRecordPageDto(
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CustomEntityRecordReadDto.fromJson)
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }
}
