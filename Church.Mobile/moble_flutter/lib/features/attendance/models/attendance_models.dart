import 'attendance_criterion_models.dart';

enum AttendanceStatus {
  present(1),
  absent(2),
  late(3),
  excused(4);

  final int value;
  const AttendanceStatus(this.value);

  /// PascalCase name matching ASP.NET `JsonStringEnumConverter` output
  /// (e.g. `"Present"`).
  String get apiName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.excused:
        return 'Excused';
    }
  }

  static AttendanceStatus fromValue(int value) =>
      AttendanceStatus.values.firstWhere((e) => e.value == value,
          orElse: () => AttendanceStatus.absent);

  /// Parses API `status`: string enum names (`"Present"`) or ints (`1`).
  /// Backend uses `JsonStringEnumConverter` with `allowIntegerValues: true`.
  static AttendanceStatus fromJson(dynamic raw) {
    if (raw == null) return AttendanceStatus.absent;
    if (raw is int) return fromValue(raw);
    if (raw is num) return fromValue(raw.toInt());
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return AttendanceStatus.absent;
      final asInt = int.tryParse(trimmed);
      if (asInt != null) return fromValue(asInt);
      switch (trimmed.toLowerCase()) {
        case 'present':
          return AttendanceStatus.present;
        case 'absent':
          return AttendanceStatus.absent;
        case 'late':
          return AttendanceStatus.late;
        case 'excused':
          return AttendanceStatus.excused;
        default:
          return AttendanceStatus.absent;
      }
    }
    return AttendanceStatus.absent;
  }

  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.excused:
        return 'Excused';
    }
  }
}

/// Unified attendance record DTO used for reading and local state.
/// - [memberId] corresponds to ChildId in read responses and MemberId in
///   add/update requests (the backend uses different field names).
/// - [id] is populated when reading an existing record (for updates).
class AttendanceRecordDto {
  final int? id;
  final int memberId;
  final String? memberName;
  final bool madeHomeWork;
  final bool hasTools;
  final int status;
  final String? note;
  final List<AttendanceCriterionResultDto> criterionResults;

  const AttendanceRecordDto({
    this.id,
    required this.memberId,
    this.memberName,
    required this.madeHomeWork,
    required this.hasTools,
    required this.status,
    this.note,
    this.criterionResults = const [],
  });

  factory AttendanceRecordDto.fromJson(Map<String, dynamic> json) =>
      AttendanceRecordDto(
        id: json['id'] as int?,
        // Read DTO returns 'childId'; Add/Update DTOs use 'memberId'.
        memberId: (json['memberId'] ?? json['childId']) as int? ?? 0,
        memberName: (json['memberName'] ?? json['MemberName']) as String?,
        madeHomeWork: json['madeHomeWork'] as bool? ?? false,
        hasTools: json['hasTools'] as bool? ?? false,
        status: AttendanceStatus.fromJson(json['status']).value,
        note: json['note'] as String?,
        criterionResults: (json['criterionResults'] as List<dynamic>?)
                ?.map((e) => AttendanceCriterionResultDto.fromJson(
                      e as Map<String, dynamic>,
                    ))
                .toList() ??
            const [],
      );

  /// JSON for creating a new attendance record (AttendanceRecordAddDTO).
  Map<String, dynamic> toAddJson() => {
        'memberId': memberId,
        'madeHomeWork': madeHomeWork,
        'hasTools': hasTools,
        'status': AttendanceStatus.fromValue(status).apiName,
        if (note != null) 'note': note,
        'criterionResults':
            criterionResults.map((r) => r.toAddJson()).toList(),
      };

  /// JSON for updating an existing attendance record (AttendanceRecordUpdateDTO).
  Map<String, dynamic> toUpdateJson() => {
        if (id != null) 'id': id,
        'memberId': memberId,
        'madeHomeWork': madeHomeWork,
        'hasTools': hasTools,
        'status': AttendanceStatus.fromValue(status).apiName,
        if (note != null) 'note': note,
        'criterionResults':
            criterionResults.map((r) => r.toAddJson()).toList(),
      };
}

class AttendanceSessionAddDto {
  final int? classroomId;
  final int? meetingId;
  final int? takenByServantId;
  final String? notes;
  final List<AttendanceRecordDto> records;

  const AttendanceSessionAddDto({
    this.classroomId,
    this.meetingId,
    this.takenByServantId,
    this.notes,
    required this.records,
  });

  Map<String, dynamic> toJson() => {
        if (classroomId != null) 'classroomId': classroomId,
        if (meetingId != null) 'meetingId': meetingId,
        if (takenByServantId != null) 'takenByServantId': takenByServantId,
        if (notes != null) 'notes': notes,
        'records': records.map((r) => r.toAddJson()).toList(),
      };
}

class AttendanceSessionUpdateDto {
  final int id;
  final int? classroomId;
  final int? meetingId;
  final int? takenByServantId;
  final String? notes;
  final String? createdAt;
  final List<AttendanceRecordDto> records;

  const AttendanceSessionUpdateDto({
    required this.id,
    this.classroomId,
    this.meetingId,
    this.takenByServantId,
    this.notes,
    this.createdAt,
    required this.records,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        if (classroomId != null) 'classroomId': classroomId,
        if (meetingId != null) 'meetingId': meetingId,
        if (takenByServantId != null) 'takenByServantId': takenByServantId,
        if (notes != null) 'notes': notes,
        if (createdAt != null) 'createdAt': createdAt,
        'records': records.map((r) => r.toUpdateJson()).toList(),
      };
}

class AttendanceSessionReadDto {
  final String? createdAt;
  final int? takenByServantId;
  final String? notes;
  final List<AttendanceRecordDto> records;

  const AttendanceSessionReadDto({
    this.createdAt,
    this.takenByServantId,
    this.notes,
    required this.records,
  });

  factory AttendanceSessionReadDto.fromJson(Map<String, dynamic> json) =>
      AttendanceSessionReadDto(
        createdAt: json['createdAt'] as String?,
        takenByServantId: json['takenByServantId'] as int?,
        notes: json['notes'] as String?,
        records: (json['records'] as List<dynamic>?)
                ?.map((e) =>
                    AttendanceRecordDto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class AttendanceSessionSummaryDto {
  final int id;
  final String? createdAt;
  final String? notes;
  final int recordsCount;

  const AttendanceSessionSummaryDto({
    required this.id,
    this.createdAt,
    this.notes,
    required this.recordsCount,
  });

  factory AttendanceSessionSummaryDto.fromJson(Map<String, dynamic> json) =>
      AttendanceSessionSummaryDto(
        id: json['id'] as int? ?? 0,
        createdAt: json['createdAt']?.toString(),
        notes: json['notes'] as String?,
        recordsCount: json['recordsCount'] as int? ?? 0,
      );
}
