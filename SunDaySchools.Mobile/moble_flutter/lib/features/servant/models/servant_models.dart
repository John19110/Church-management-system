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
  /// Primary key from API (`id` in JSON).
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

class NamedEntityDto {
  final int id;
  final String? name;

  const NamedEntityDto({required this.id, this.name});

  factory NamedEntityDto.fromJson(Map<String, dynamic> json) => NamedEntityDto(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String?,
      );
}

class ServantProfileDto {
  final int id;
  final String? name;
  final String? phoneNumber;
  final String? imageUrl;
  final String? birthDate;
  final String? joiningDate;
  final String? spiritualBirthDate;
  final NamedEntityDto? church;
  final NamedEntityDto? meeting;
  final List<ClassroomSummaryDto> classrooms;

  const ServantProfileDto({
    required this.id,
    this.name,
    this.phoneNumber,
    this.imageUrl,
    this.birthDate,
    this.joiningDate,
    this.spiritualBirthDate,
    this.church,
    this.meeting,
    this.classrooms = const [],
  });

  factory ServantProfileDto.fromJson(Map<String, dynamic> json) => ServantProfileDto(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        imageUrl: json['imageUrl'] as String?,
        birthDate: json['birthDate']?.toString(),
        joiningDate: json['joiningDate']?.toString(),
        spiritualBirthDate: (json['spiritualBirthDate'] ?? json['SpiritualBirthDate'])?.toString(),
        church: json['church'] is Map<String, dynamic>
            ? NamedEntityDto.fromJson(json['church'] as Map<String, dynamic>)
            : (json['Church'] is Map<String, dynamic>
                ? NamedEntityDto.fromJson(json['Church'] as Map<String, dynamic>)
                : null),
        meeting: json['meeting'] is Map<String, dynamic>
            ? NamedEntityDto.fromJson(json['meeting'] as Map<String, dynamic>)
            : (json['Meeting'] is Map<String, dynamic>
                ? NamedEntityDto.fromJson(json['Meeting'] as Map<String, dynamic>)
                : null),
        classrooms: ((json['classrooms'] ?? json['Classrooms']) as List<dynamic>?)
                ?.map((e) => ClassroomSummaryDto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
