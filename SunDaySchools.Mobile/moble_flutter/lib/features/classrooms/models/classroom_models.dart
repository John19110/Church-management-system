/// Shared selection option returned by `/select` endpoints.
class SelectOptionDto {
  final int id;
  final String name;

  const SelectOptionDto({required this.id, required this.name});

  factory SelectOptionDto.fromJson(Map<String, dynamic> json) =>
      SelectOptionDto(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
      );
}

class ClassroomReadDto {
  final String? name;
  final String? ageOfMembers;
  final int? numberOfDisciplineMembers;
  final int? totalMembersCount;

  const ClassroomReadDto({
    this.name,
    this.ageOfMembers,
    this.numberOfDisciplineMembers,
    this.totalMembersCount,
  });

  factory ClassroomReadDto.fromJson(Map<String, dynamic> json) =>
      ClassroomReadDto(
        name: json['name'] as String?,
        ageOfMembers: json['ageOfMembers'] as String?,
        // The key 'numberOfDisplineMembers' matches the backend's Classroom model
        // which contains this spelling (typo preserved from the C# entity).
        numberOfDisciplineMembers:
            json['numberOfDisplineMembers'] as int?,
        totalMembersCount: json['totalMembersCount'] as int?,
      );
}

class ClassroomAddDto {
  final String? name;
  final String? ageOfMembers;
  final List<int>? servantIds;
  final List<int>? memberIds;
  final int? meetingId;

  const ClassroomAddDto({
    this.name,
    this.ageOfMembers,
    this.servantIds,
    this.memberIds,
    this.meetingId,
  });

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (ageOfMembers != null) 'ageOfMembers': ageOfMembers,
        if (servantIds != null) 'servantIds': servantIds,
        if (memberIds != null) 'memberIds': memberIds,
        if (meetingId != null) 'meetingId': meetingId,
      };
}
