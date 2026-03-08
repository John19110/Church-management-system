class ServantReadDto {
  final int id;
  final String? imageFileName;
  final String? imageUrl;
  final String? name;
  final String? birthDate;
  final String? joiningDate;
  final String? phoneNumber;
  final int? classroomId;

  const ServantReadDto({
    required this.id,
    this.imageFileName,
    this.imageUrl,
    this.name,
    this.birthDate,
    this.joiningDate,
    this.phoneNumber,
    this.classroomId,
  });

  factory ServantReadDto.fromJson(Map<String, dynamic> json) => ServantReadDto(
        id: json['id'] as int,
        imageFileName: json['imageFileName'] as String?,
        imageUrl: json['imageUrl'] as String?,
        name: json['name'] as String?,
        birthDate: json['birthDate'] as String?,
        joiningDate: json['joiningDate'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        classroomId: json['classroomId'] as int?,
      );
}
