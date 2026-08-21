import 'package:flutter/material.dart';

/// Matches backend [AttendanceCriterionDataType] / JsonStringEnumConverter.
class AttendanceCriterionDataType {
  static const int boolean = 1;

  /// Parses API `dataType`: string enum names (`"Boolean"`) or ints (`1`).
  static int fromJson(dynamic raw) {
    if (raw == null) return boolean;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return boolean;
      final asInt = int.tryParse(trimmed);
      if (asInt != null) return asInt;
      switch (trimmed.toLowerCase()) {
        case 'boolean':
          return boolean;
        default:
          return boolean;
      }
    }
    return boolean;
  }
}

class AttendanceCriterionDto {
  final int id;
  final int meetingId;
  final String name;
  final String displayName;
  final String? displayNameAr;
  final int dataType;
  final bool isActive;
  final int sortOrder;

  const AttendanceCriterionDto({
    required this.id,
    required this.meetingId,
    required this.name,
    required this.displayName,
    this.displayNameAr,
    this.dataType = AttendanceCriterionDataType.boolean,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory AttendanceCriterionDto.fromJson(Map<String, dynamic> json) =>
      AttendanceCriterionDto(
        id: json['id'] as int? ?? 0,
        meetingId: json['meetingId'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        displayNameAr: json['displayNameAr'] as String?,
        dataType: AttendanceCriterionDataType.fromJson(json['dataType']),
        isActive: json['isActive'] as bool? ?? true,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );

  String labelForLocale(Locale? locale) {
    final isAr = locale?.languageCode.toLowerCase() == 'ar';
    if (isAr && (displayNameAr?.trim().isNotEmpty ?? false)) {
      return displayNameAr!.trim();
    }
    return displayName;
  }
}

class AttendanceCriterionResultDto {
  final int criterionId;
  final String name;
  final String displayName;
  final String? displayNameAr;
  final bool? value;

  const AttendanceCriterionResultDto({
    required this.criterionId,
    this.name = '',
    required this.displayName,
    this.displayNameAr,
    this.value,
  });

  factory AttendanceCriterionResultDto.fromJson(Map<String, dynamic> json) =>
      AttendanceCriterionResultDto(
        criterionId: json['criterionId'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        displayNameAr: json['displayNameAr'] as String?,
        value: json['value'] as bool?,
      );

  Map<String, dynamic> toAddJson() => {
        'criterionId': criterionId,
        'value': value ?? false,
      };

  String labelForLocale(Locale? locale) {
    final isAr = locale?.languageCode.toLowerCase() == 'ar';
    if (isAr && (displayNameAr?.trim().isNotEmpty ?? false)) {
      return displayNameAr!.trim();
    }
    return displayName;
  }
}
