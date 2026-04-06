class MeetingAddDto {
  final String? name;
  final DateTime weeklyAppointment;

  const MeetingAddDto({this.name, required this.weeklyAppointment});

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        'weekly_appointment': weeklyAppointment.toIso8601String(),
      };
}

// SelectOptionDto is shared — re-exported for convenience.
export '../../../features/classrooms/models/classroom_models.dart'
    show SelectOptionDto;
