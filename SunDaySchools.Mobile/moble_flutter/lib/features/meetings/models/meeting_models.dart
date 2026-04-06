export '../../../features/classrooms/models/classroom_models.dart'
    show SelectOptionDto;

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
  final List<String> memberNames;
  final List<String> servantNames;

  const MeetingReadDto({
    this.name,
    this.weeklyAppointment,
    required this.membersCount,
    required this.servantsCount,
    this.memberNames = const [],
    this.servantNames = const [],
  });

  factory MeetingReadDto.fromJson(Map<String, dynamic> json) => MeetingReadDto(
        name: json['name'] as String?,
        weeklyAppointment: DateTime.tryParse(
          // Backend currently uses `Weekly_appointment`; keep camelCase fallback
          // for compatibility with potential serializer naming changes.
          (json['weekly_appointment'] ??
                  json['Weekly_appointment'] ??
                  json['weeklyAppointment'] ??
                  '')
              .toString(),
        ),
        membersCount: _asList(json['members']).length,
        servantsCount: _asList(json['servants']).length,
        memberNames: _extractDisplayNames(_asList(json['members'])),
        servantNames: _extractDisplayNames(_asList(json['servants'])),
      );

  static List<dynamic> _asList(dynamic value) {
    return value is List ? value : <dynamic>[];
  }

  static List<String> _extractDisplayNames(List<dynamic> items) {
    return items
        .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
        .map(
          (item) =>
              (item['fullName'] ??
                      item['name'] ??
                      item['Name'] ??
                      item['Name1'] ??
                      '')
                  .toString()
                  .trim(),
        )
        .where((name) => name.isNotEmpty)
        .toList();
  }
}
