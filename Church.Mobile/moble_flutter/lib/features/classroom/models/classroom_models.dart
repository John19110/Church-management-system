class ClassroomReadDto {
  final int? id;
  final String? name;
  final String? ageOfMembers;
  final int? meetingId;
  final int? numberOfDisciplineMembers;
  final int? totalMembersCount;
  final int? pastAttendanceSessionsCount;
  final int? leaderServantId;
  final String? leaderServantName;
  final List<String> memberNames;
  final List<String> servantNames;

  const ClassroomReadDto({
    this.id,
    this.name,
    this.ageOfMembers,
    this.meetingId,
    this.numberOfDisciplineMembers,
    this.totalMembersCount,
    this.pastAttendanceSessionsCount,
    this.leaderServantId,
    this.leaderServantName,
    this.memberNames = const [],
    this.servantNames = const [],
  });

  factory ClassroomReadDto.fromJson(Map<String, dynamic> json) =>
      ClassroomReadDto(
        id: json['id'] as int?,
        name: json['name'] as String?,
        ageOfMembers: json['ageOfMembers'] as String?,
        meetingId: json['meetingId'] as int?,
        // The key 'numberOfDisplineMembers' matches the backend's Classroom model
        // which contains this spelling (typo preserved from the C# entity).
        numberOfDisciplineMembers:
            json['numberOfDisplineMembers'] as int?,
        totalMembersCount: json['totalMembersCount'] as int?,
        pastAttendanceSessionsCount:
            json['pastAttendanceSessionsCount'] as int?,
        leaderServantId: json['leaderServantId'] as int?,
        leaderServantName: json['leaderServantName'] as String?,
        memberNames: _extractDisplayNames(_asList(json['members'])),
        servantNames: _extractDisplayNames(_asList(json['servants'])),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ageOfMembers': ageOfMembers,
        'meetingId': meetingId,
        'numberOfDisplineMembers': numberOfDisciplineMembers,
        'totalMembersCount': totalMembersCount,
        'pastAttendanceSessionsCount': pastAttendanceSessionsCount,
        'leaderServantId': leaderServantId,
        'leaderServantName': leaderServantName,
        'memberNames': memberNames,
        'servantNames': servantNames,
      };

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

class ClassroomAddDto {
  final String? name;
  final String? ageOfMembers;
  final List<int>? servantIds;
  final List<int>? memberIds;
  final int? meetingId;
  final int? leaderServantId;

  const ClassroomAddDto({
    this.name,
    this.ageOfMembers,
    this.servantIds,
    this.memberIds,
    this.meetingId,
    this.leaderServantId,
  });

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (ageOfMembers != null) 'ageOfMembers': ageOfMembers,
        if (servantIds != null) 'servantIds': servantIds,
        if (memberIds != null) 'memberIds': memberIds,
        if (meetingId != null) 'meetingId': meetingId,
        if (leaderServantId != null) 'leaderServantId': leaderServantId,
      };
}
