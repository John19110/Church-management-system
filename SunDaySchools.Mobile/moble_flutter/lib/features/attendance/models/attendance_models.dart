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

class AttendanceRecordDto {
  final int? id;
  final int childId;
  final bool madeHomeWork;
  final bool hasTools;
  final int status;
  final String? note;

  const AttendanceRecordDto({
    this.id,
    required this.childId,
    required this.madeHomeWork,
    required this.hasTools,
    required this.status,
    this.note,
  });

  factory AttendanceRecordDto.fromJson(Map<String, dynamic> json) =>
      AttendanceRecordDto(
        id: json['id'] as int?,
        childId: json['childId'] as int,
        madeHomeWork: json['madeHomeWork'] as bool? ?? false,
        hasTools: json['hasTools'] as bool? ?? false,
        status: json['status'] as int? ?? 2,
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'childId': childId,
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
        'records': records.map((r) => r.toJson()).toList(),
      };
}

class AttendanceSessionUpdateDto extends AttendanceSessionAddDto {
  final int id;
  final String? createdAt;

  const AttendanceSessionUpdateDto({
    required this.id,
    required super.classroomId,
    super.takenByServantId,
    super.notes,
    required super.records,
    this.createdAt,
  });

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        ...super.toJson(),
        if (createdAt != null) 'createdAt': createdAt,
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
