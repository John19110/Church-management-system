class MemberContactDto {
  final String? relation;
  final String? phoneNumber;

  const MemberContactDto({this.relation, this.phoneNumber});

  factory MemberContactDto.fromJson(Map<String, dynamic> json) => MemberContactDto(
        relation: json['relation'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'relation': relation,
        'phoneNumber': phoneNumber,
      };
}

class MemberReadDto {
  /// Note: the API's MemberReadDTO does not currently include an Id field.
  /// This will be 0 when the backend does not return it.
  final int id;
  final String? fullName;
  final String? imageFileName;
  final String? imageUrl;
  final String? address;
  final String? gender;
  final String? dateOfBirth;
  final String? joiningDate;
  final String? lastAttendanceDate;
  final String? spiritualDateOfBirth;
  final bool? isDiscipline;
  final int? totalNumberOfDaysAttended;
  final List<MemberContactDto>? phoneNumbers;
  final bool? haveBrothers;
  final List<String>? brothersNames;
  final int? classroomId;
  final List<String>? notes;

  const MemberReadDto({
    required this.id,
    this.fullName,
    this.imageFileName,
    this.imageUrl,
    this.address,
    this.gender,
    this.dateOfBirth,
    this.joiningDate,
    this.lastAttendanceDate,
    this.spiritualDateOfBirth,
    this.isDiscipline,
    this.totalNumberOfDaysAttended,
    this.phoneNumbers,
    this.haveBrothers,
    this.brothersNames,
    this.classroomId,
    this.notes,
  });

  factory MemberReadDto.fromJson(Map<String, dynamic> json) => MemberReadDto(
        id: json['id'] as int? ?? 0,
        fullName: json['fullName'] as String?,
        imageFileName: json['imageFileName'] as String?,
        imageUrl: json['imageUrl'] as String?,
        address: json['address'] as String?,
        gender: json['gender'] as String?,
        dateOfBirth: json['dateOfBirth'] as String?,
        joiningDate: json['joiningDate'] as String?,
        lastAttendanceDate: json['lastAttendanceDate'] as String?,
        spiritualDateOfBirth: json['spiritualDateOfBirth'] as String?,
        isDiscipline: json['isDiscipline'] as bool?,
        totalNumberOfDaysAttended: json['totalNumberOfDaysAttended'] as int?,
        phoneNumbers: (json['phoneNumbers'] as List<dynamic>?)
            ?.map((e) => MemberContactDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        haveBrothers: json['haveBrothers'] as bool?,
        brothersNames: (json['brothersNames'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        classroomId: json['classroomId'] as int?,
        notes: (json['notes'] as List<dynamic>?)?.map((e) => e as String).toList(),
      );
}

class MemberAddDto {
  final String? name1;
  final String? name2;
  final String? name3;
  final String? gender;
  final String? address;
  final String? dateOfBirth;
  final String? joiningDate;
  final String? spiritualDateOfBirth;
  final List<String>? notes;
  final List<String>? brothersNames;
  final bool? haveBrothers;
  final List<MemberContactDto>? phoneNumbers;

  const MemberAddDto({
    this.name1,
    this.name2,
    this.name3,
    this.gender,
    this.address,
    this.dateOfBirth,
    this.joiningDate,
    this.spiritualDateOfBirth,
    this.notes,
    this.brothersNames,
    this.haveBrothers,
    this.phoneNumbers,
  });

  Map<String, dynamic> toJson() => {
        if (name1 != null) 'name1': name1,
        if (name2 != null) 'name2': name2,
        if (name3 != null) 'name3': name3,
        if (gender != null) 'gender': gender,
        if (address != null) 'address': address,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        if (joiningDate != null) 'joiningDate': joiningDate,
        if (spiritualDateOfBirth != null)
          'spiritualDateOfBirth': spiritualDateOfBirth,
        if (notes != null) 'notes': notes,
        if (brothersNames != null) 'brothersNames': brothersNames,
        if (haveBrothers != null) 'haveBrothers': haveBrothers,
        if (phoneNumbers != null)
          'phoneNumbers': phoneNumbers!.map((e) => e.toJson()).toList(),
      };
}

class MemberUpdateDto extends MemberAddDto {
  final int id;
  final String? lastAttendanceDate;
  final bool? isDiscipline;
  final int? totalNumberOfDaysAttended;
  final int? classroomId;

  const MemberUpdateDto({
    required this.id,
    super.name1,
    super.name2,
    super.name3,
    super.gender,
    super.address,
    super.dateOfBirth,
    super.joiningDate,
    super.spiritualDateOfBirth,
    super.notes,
    super.brothersNames,
    super.haveBrothers,
    super.phoneNumbers,
    this.lastAttendanceDate,
    this.isDiscipline,
    this.totalNumberOfDaysAttended,
    this.classroomId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        ...super.toJson(),
        if (lastAttendanceDate != null) 'lastAttendanceDate': lastAttendanceDate,
        if (isDiscipline != null) 'isDiscipline': isDiscipline,
        if (totalNumberOfDaysAttended != null)
          'totalNumberOfDaysAttended': totalNumberOfDaysAttended,
        if (classroomId != null) 'classroomId': classroomId,
      };
}
