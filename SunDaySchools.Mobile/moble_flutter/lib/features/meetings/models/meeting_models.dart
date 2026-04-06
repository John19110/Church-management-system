class MeetingAddDto {
  final String? name;
  final DateTime weeklyAppointment;

  const MeetingAddDto({this.name, required this.weeklyAppointment});

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        'weekly_appointment': weeklyAppointment.toIso8601String(),
      };
}

class MeetingReadDto {
  final String? name;
  final DateTime? weeklyAppointment;
  final int membersCount;
  final int servantsCount;

  const MeetingReadDto({
    this.name,
    this.weeklyAppointment,
    required this.membersCount,
    required this.servantsCount,
  });

  factory MeetingReadDto.fromJson(Map<String, dynamic> json) => MeetingReadDto(
        name: json['name'] as String?,
        weeklyAppointment: DateTime.tryParse(
          // Backend currently uses `Weekly_appointment`; keep camelCase fallback
          // for compatibility with potential serializer naming changes.
          (json['weekly_appointment'] ?? json['weeklyAppointment'] ?? '')
              .toString(),
        ),
        membersCount: (json['members'] as List<dynamic>?)?.length ?? 0,
        servantsCount: (json['servants'] as List<dynamic>?)?.length ?? 0,
      );
}

// SelectOptionDto is shared — re-exported for convenience.
export '../../../features/classrooms/models/classroom_models.dart'
    show SelectOptionDto;
