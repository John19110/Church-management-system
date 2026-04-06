class ClassroomSummaryDto {
  final int id;
  final String? name;
  final String? ageOfMembers;

  const ClassroomSummaryDto({
    required this.id,
    this.name,
    this.ageOfMembers,
  });

  factory ClassroomSummaryDto.fromJson(Map<String, dynamic> json) =>
      ClassroomSummaryDto(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String?,
        ageOfMembers: json['ageOfMembers'] as String?,
      );
}

class ServantReadDto {
  /// Note: the API's ServantReadDTO does not currently include an Id field.
  /// This will be 0 when the backend does not return it.
  final int id;
  final String? imageFileName;
  final String? imageUrl;
  final String? name;
  final String? birthDate;
  final String? joiningDate;
  final String? phoneNumber;
  final List<ClassroomSummaryDto> classrooms;

  const ServantReadDto({
    required this.id,
    this.imageFileName,
    this.imageUrl,
    this.name,
    this.birthDate,
    this.joiningDate,
    this.phoneNumber,
    this.classrooms = const [],
  });

  factory ServantReadDto.fromJson(Map<String, dynamic> json) => ServantReadDto(
        id: json['id'] as int? ?? 0,
        imageFileName: json['imageFileName'] as String?,
        imageUrl: json['imageUrl'] as String?,
        name: json['name'] as String?,
        birthDate: json['birthDate'] as String?,
        joiningDate: json['joiningDate'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        classrooms: (json['classrooms'] as List<dynamic>?)
                ?.map((e) =>
                    ClassroomSummaryDto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
