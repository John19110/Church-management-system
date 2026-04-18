import 'package:flutter/material.dart';

export '../../../features/classroom/models/classroom_models.dart'
    show SelectOptionDto;

class MeetingAddDto {
  final String? name;
  final TimeOfDay weeklyAppointment;
  final String dayOfWeek;

  const MeetingAddDto({
    this.name,
    required this.weeklyAppointment,
    required this.dayOfWeek,
  });

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        'weeklyAppointment': _formatTime(weeklyAppointment),
        'dayOfWeek': dayOfWeek,
      };

  static String _formatTime(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm:00';
  }
}

class MeetingReadDto {
  final String? name;
  final String? weeklyAppointment;
  final String? dayOfWeek;
  final int membersCount;
  final int servantsCount;
  final List<String> memberNames;
  final List<String> servantNames;

  const MeetingReadDto({
    this.name,
    this.weeklyAppointment,
    this.dayOfWeek,
    required this.membersCount,
    required this.servantsCount,
    this.memberNames = const [],
    this.servantNames = const [],
  });

  factory MeetingReadDto.fromJson(Map<String, dynamic> json) => MeetingReadDto(
        name: json['name'] as String?,
        weeklyAppointment: (json['weeklyAppointment'] ??
                json['weekly_appointment'] ??
                json['Weekly_appointment'] ??
                '')
            .toString()
            .trim()
            .isEmpty
            ? null
            : (json['weeklyAppointment'] ??
                    json['weekly_appointment'] ??
                    json['Weekly_appointment'])
                .toString(),
        dayOfWeek: (json['dayOfWeek'] ?? json['DayOfWeek'])?.toString(),
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
                      // Backend Member entity can serialize first-name as Name1.
                      item['Name1'] ??
                      '')
                  .toString()
                  .trim(),
        )
        .where((name) => name.isNotEmpty)
        .toList();
  }
}
