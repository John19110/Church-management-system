enum AttendanceStatus {
  present(1),
  absent(2),
  late(3),
  excused(4);

  final int value;
  const AttendanceStatus(this.value);

  static AttendanceStatus fromValue(int value) =>
      AttendanceStatus.values.firstWhere((e) => e.value == value,
          orElse: () => AttendanceStatus.absent);

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
  final bool madeHomeWork;
  final bool hasTools;
  final int status;
  final String? note;

  const AttendanceRecordDto({
    this.id,
    required this.memberId,
    required this.madeHomeWork,
    required this.hasTools,
    required this.status,
    this.note,
  });

  factory AttendanceRecordDto.fromJson(Map<String, dynamic> json) =>
      AttendanceRecordDto(
        id: json['id'] as int?,
        // Read DTO returns 'childId'; Add/Update DTOs use 'memberId'.
        memberId: (json['memberId'] ?? json['childId']) as int? ?? 0,
        madeHomeWork: json['madeHomeWork'] as bool? ?? false,
        hasTools: json['hasTools'] as bool? ?? false,
        status: json['status'] as int? ?? 2,
        note: json['note'] as String?,
      );

  /// JSON for creating a new attendance record (AttendanceRecordAddDTO).
  Map<String, dynamic> toAddJson() => {
        'memberId': memberId,
        'madeHomeWork': madeHomeWork,
        'hasTools': hasTools,
        'status': status,
        if (note != null) 'note': note,
      };

  /// JSON for updating an existing attendance record (AttendanceRecordUpdateDTO).
  Map<String, dynamic> toUpdateJson() => {
        if (id != null) 'id': id,
        'memberId': memberId,
        'madeHomeWork': madeHomeWork,
        'hasTools': hasTools,
        'status': status,
        if (note != null) 'note': note,
      };
}

class AttendanceSessionAddDto {
  final int classroomId;
  final int? takenByServantId;
  final String? notes;
  final List<AttendanceRecordDto> records;

  const AttendanceSessionAddDto({
    required this.classroomId,
    this.takenByServantId,
    this.notes,
    required this.records,
  });

  Map<String, dynamic> toJson() => {
        'classroomId': classroomId,
        if (takenByServantId != null) 'takenByServantId': takenByServantId,
        if (notes != null) 'notes': notes,
        'records': records.map((r) => r.toAddJson()).toList(),
      };
}

class AttendanceSessionUpdateDto {
  final int id;
  final int classroomId;
  final int? takenByServantId;
  final String? notes;
  final String? createdAt;
  final List<AttendanceRecordDto> records;

  const AttendanceSessionUpdateDto({
    required this.id,
    required this.classroomId,
    this.takenByServantId,
    this.notes,
    this.createdAt,
    required this.records,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'classroomId': classroomId,
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
