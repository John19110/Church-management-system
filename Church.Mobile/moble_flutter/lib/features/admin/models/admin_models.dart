class PendingUserDto {
  final String id;
  final String name;
  final String phoneNumber;

  const PendingUserDto({
    required this.id,
    required this.name,
    required this.phoneNumber,
  });

  factory PendingUserDto.fromJson(Map<String, dynamic> json) => PendingUserDto(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        phoneNumber: json['phoneNumber'] as String? ?? '',
      );
}

class AdminAddServantDto {
  // Account fields (mirrors the backend's RegisterServamtinAddAdmin DTO —
  // the backend class name contains a typo that is preserved intentionally).
  final String accountName;
  final String phoneNumber;
  final String password;
  final String confirmPassword;
  final String? birthDate;
  final String? joiningDate;
  final List<int>? classroomsIds;

  // Servant profile fields (ServantAddDTO)
  final String? servantBirthDate;
  final String? servantJoiningDate;

  const AdminAddServantDto({
    required this.accountName,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
    this.birthDate,
    this.joiningDate,
    this.classroomsIds,
    this.servantBirthDate,
    this.servantJoiningDate,
  });
}
