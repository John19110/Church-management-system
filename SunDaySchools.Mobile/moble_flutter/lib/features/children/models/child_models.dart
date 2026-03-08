class ChildContactDto {
  final String? relation;
  final String? phoneNumber;

  const ChildContactDto({this.relation, this.phoneNumber});

  factory ChildContactDto.fromJson(Map<String, dynamic> json) => ChildContactDto(
        relation: json['relation'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'relation': relation,
        'phoneNumber': phoneNumber,
      };
}

class ChildReadDto {
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
  final bool? isDisciplineChild;
  final int? totalNumberOfDaysAttended;
  final List<ChildContactDto>? phoneNumbers;
  final bool? haveBrothers;
  final List<String>? brothersNames;
  final int? classroomId;
  final List<String>? notes;

  const ChildReadDto({
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
    this.isDisciplineChild,
    this.totalNumberOfDaysAttended,
    this.phoneNumbers,
    this.haveBrothers,
    this.brothersNames,
    this.classroomId,
    this.notes,
  });

  factory ChildReadDto.fromJson(Map<String, dynamic> json) => ChildReadDto(
        id: json['id'] as int,
        fullName: json['fullName'] as String?,
        imageFileName: json['imageFileName'] as String?,
        imageUrl: json['imageUrl'] as String?,
        address: json['address'] as String?,
        gender: json['gender'] as String?,
        dateOfBirth: json['dateOfBirth'] as String?,
        joiningDate: json['joiningDate'] as String?,
        lastAttendanceDate: json['lastAttendanceDate'] as String?,
        spiritualDateOfBirth: json['spiritualDateOfBirth'] as String?,
        isDisciplineChild: json['isDisciplineChild'] as bool?,
        totalNumberOfDaysAttended: json['totalNumberOfDaysAttended'] as int?,
        phoneNumbers: (json['phoneNumbers'] as List<dynamic>?)
            ?.map((e) => ChildContactDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        haveBrothers: json['haveBrothers'] as bool?,
        brothersNames: (json['brothersNames'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        classroomId: json['classroomId'] as int?,
        notes: (json['notes'] as List<dynamic>?)?.map((e) => e as String).toList(),
      );
}

class ChildAddDto {
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
  final int? classroomId;
  final List<ChildContactDto>? phoneNumbers;

  const ChildAddDto({
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
    this.classroomId,
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
        if (classroomId != null) 'classroomId': classroomId,
        if (phoneNumbers != null)
          'phoneNumbers': phoneNumbers!.map((e) => e.toJson()).toList(),
      };
}

class ChildUpdateDto extends ChildAddDto {
  final int id;
  final String? lastAttendanceDate;
  final bool? isDisciplineChild;
  final int? totalNumberOfDaysAttended;

  const ChildUpdateDto({
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
    super.classroomId,
    super.phoneNumbers,
    this.lastAttendanceDate,
    this.isDisciplineChild,
    this.totalNumberOfDaysAttended,
  });

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        ...super.toJson(),
        if (lastAttendanceDate != null) 'lastAttendanceDate': lastAttendanceDate,
        if (isDisciplineChild != null) 'isDisciplineChild': isDisciplineChild,
        if (totalNumberOfDaysAttended != null)
          'totalNumberOfDaysAttended': totalNumberOfDaysAttended,
      };
}
