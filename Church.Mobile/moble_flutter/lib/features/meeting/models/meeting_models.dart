import 'package:flutter/material.dart';

class MeetingAddDto {
  final String? name;
  final TimeOfDay weeklyAppointment;
  final String dayOfWeek;
  final bool hasClassrooms;

  const MeetingAddDto({
    this.name,
    required this.weeklyAppointment,
    required this.dayOfWeek,
    this.hasClassrooms = true,
  });

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        'weeklyAppointment': _formatTime(weeklyAppointment),
        'dayOfWeek': dayOfWeek,
        'hasClassrooms': hasClassrooms,
      };

  static String _formatTime(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm:00';
  }
}

class MeetingReadDto {
  final int? id;
  final String publicId;
  final String? name;
  final String? weeklyAppointment;
  final String? dayOfWeek;
  final bool hasClassrooms;
  final MemberViewMode memberViewMode;
  final List<int> allMembersViewerServantIds;
  final bool canViewAllMembers;
  final int membersCount;
  final int servantsCount;
  final List<String> memberNames;
  final List<String> servantNames;
  final int? leaderServantId;

  const MeetingReadDto({
    this.id,
    this.publicId = '',
    this.name,
    this.weeklyAppointment,
    this.dayOfWeek,
    this.hasClassrooms = true,
    this.memberViewMode = MemberViewMode.assignedOnly,
    this.allMembersViewerServantIds = const [],
    this.canViewAllMembers = false,
    required this.membersCount,
    required this.servantsCount,
    this.memberNames = const [],
    this.servantNames = const [],
    this.leaderServantId,
  });

  factory MeetingReadDto.fromJson(Map<String, dynamic> json) => MeetingReadDto(
        id: json['id'] as int?,
        publicId: json['publicId'] as String? ?? '',
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
        hasClassrooms: json['hasClassrooms'] as bool? ??
            json['HasClassrooms'] as bool? ??
            true,
        memberViewMode: MemberViewMode.fromJson(
          json['memberViewMode'] ?? json['MemberViewMode'],
        ),
        allMembersViewerServantIds: _asIntList(
          json['allMembersViewerServantIds'] ??
              json['AllMembersViewerServantIds'],
        ),
        canViewAllMembers: json['canViewAllMembers'] as bool? ??
            json['CanViewAllMembers'] as bool? ??
            false,
        membersCount: _asList(json['members']).length,
        servantsCount: _asList(json['servants']).length,
        memberNames: _extractDisplayNames(_asList(json['members'])),
        servantNames: _extractDisplayNames(_asList(json['servants'])),
        leaderServantId: json['leaderServantId'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'publicId': publicId,
        'name': name,
        'weeklyAppointment': weeklyAppointment,
        'dayOfWeek': dayOfWeek,
        'hasClassrooms': hasClassrooms,
        'memberViewMode': memberViewMode.apiValue,
        'allMembersViewerServantIds': allMembersViewerServantIds,
        'canViewAllMembers': canViewAllMembers,
        'leaderServantId': leaderServantId,
        'membersCount': membersCount,
        'servantsCount': servantsCount,
        'memberNames': memberNames,
        'servantNames': servantNames,
      };

  MeetingReadDto copyWith({
    int? id,
    String? publicId,
    String? name,
    String? weeklyAppointment,
    String? dayOfWeek,
    bool? hasClassrooms,
    MemberViewMode? memberViewMode,
    List<int>? allMembersViewerServantIds,
    bool? canViewAllMembers,
    int? membersCount,
    int? servantsCount,
    List<String>? memberNames,
    List<String>? servantNames,
    int? leaderServantId,
  }) {
    return MeetingReadDto(
      id: id ?? this.id,
      publicId: publicId ?? this.publicId,
      name: name ?? this.name,
      weeklyAppointment: weeklyAppointment ?? this.weeklyAppointment,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      hasClassrooms: hasClassrooms ?? this.hasClassrooms,
      memberViewMode: memberViewMode ?? this.memberViewMode,
      allMembersViewerServantIds:
          allMembersViewerServantIds ?? this.allMembersViewerServantIds,
      canViewAllMembers: canViewAllMembers ?? this.canViewAllMembers,
      membersCount: membersCount ?? this.membersCount,
      servantsCount: servantsCount ?? this.servantsCount,
      memberNames: memberNames ?? this.memberNames,
      servantNames: servantNames ?? this.servantNames,
      leaderServantId: leaderServantId ?? this.leaderServantId,
    );
  }

  static List<dynamic> _asList(dynamic value) {
    return value is List ? value : <dynamic>[];
  }

  static List<int> _asIntList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((e) {
          if (e is int) return e;
          if (e is num) return e.toInt();
          return int.tryParse(e.toString());
        })
        .whereType<int>()
        .toList();
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

/// Mirrors backend [MemberViewMode].
enum MemberViewMode {
  assignedOnly,
  allAndAssigned;

  String get apiValue => switch (this) {
        MemberViewMode.assignedOnly => 'AssignedOnly',
        MemberViewMode.allAndAssigned => 'AllAndAssigned',
      };

  static MemberViewMode fromJson(dynamic value) {
    if (value is int) {
      return value == 1 ? MemberViewMode.allAndAssigned : MemberViewMode.assignedOnly;
    }
    final text = value?.toString().trim().toLowerCase() ?? '';
    if (text == '1' || text == 'allandassigned') {
      return MemberViewMode.allAndAssigned;
    }
    return MemberViewMode.assignedOnly;
  }
}
