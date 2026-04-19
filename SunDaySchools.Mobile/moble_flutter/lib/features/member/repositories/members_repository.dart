import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/select_api.dart';
import '../../../core/constants/app_constants.dart';
import '../../../features/classroom/models/classroom_models.dart';
import '../models/member_models.dart';
import '../../../core/models/select_option.dart';

class MembersRepository {
  final Dio _dio;

  MembersRepository(this._dio);

  void _requireMemberId(int id) {
    if (id <= 0) {
      throw ArgumentError.value(
        id,
        'id',
        'Member id must be a positive integer',
      );
    }
  }

  Future<List<MemberReadDto>> getAll() async {
    return apiCall(() async {
      final response = await _dio.get(AppConstants.membersEndpoint);
      final list = response.data as List<dynamic>;
      return list.map((e) => MemberReadDto.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<List<MemberReadDto>> getByClassroom(int classroomId) async {
    return apiCall(() async {
      final response = await _dio.get(
        '${AppConstants.membersEndpoint}/classroom/$classroomId',
      );
      final list = response.data as List<dynamic>;
      return list.map((e) => MemberReadDto.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<MemberReadDto> getById(int id) async {
    _requireMemberId(id);
    return apiCall(() async {
      final response = await _dio.get('${AppConstants.membersEndpoint}/$id');
      return MemberReadDto.fromJson(response.data as Map<String, dynamic>);
    });
  }

  /// Create member: POST /api/classrooms/{classroomId}/members (multipart/form-data)
  /// [classroomId] is passed as a URL path parameter.
  Future<void> create(int classroomId, MemberAddDto dto, {File? image}) async {
    return apiCall(() async {
      final map = <String, dynamic>{
        if (dto.name1 != null) 'Name1': dto.name1,
        if (dto.name2 != null) 'Name2': dto.name2,
        if (dto.name3 != null) 'Name3': dto.name3,
        if (dto.gender != null) 'Gender': dto.gender,
        if (dto.address != null) 'Address': dto.address,
        if (dto.dateOfBirth != null) 'DateOfBirth': dto.dateOfBirth,
        if (dto.joiningDate != null) 'JoiningDate': dto.joiningDate,
        if (dto.spiritualDateOfBirth != null)
          'SpiritualDateOfBirth': dto.spiritualDateOfBirth,
        if (dto.haveBrothers != null)
          'HaveBrothers': dto.haveBrothers.toString(),
        if (image != null)
          'Image': await MultipartFile.fromFile(image.path,
              filename: image.path.split('/').last),
      };
      if (dto.notes != null) {
        for (var i = 0; i < dto.notes!.length; i++) {
          map['Notes[$i]'] = dto.notes![i];
        }
      }
      if (dto.brothersNames != null) {
        for (var i = 0; i < dto.brothersNames!.length; i++) {
          map['BrothersNames[$i]'] = dto.brothersNames![i];
        }
      }
      if (dto.phoneNumbers != null) {
        for (var i = 0; i < dto.phoneNumbers!.length; i++) {
          map['PhoneNumbers[$i].Relation'] = dto.phoneNumbers![i].relation ?? '';
          map['PhoneNumbers[$i].PhoneNumber'] =
              dto.phoneNumbers![i].phoneNumber ?? '';
        }
      }
      await _dio.post(
        '${AppConstants.classroomMembersBasePath}/$classroomId/members',
        data: FormData.fromMap(map),
      );
    });
  }

  /// Update member: PUT /api/Members/{id} (JSON body)
  Future<void> update(int id, MemberUpdateDto dto) async {
    _requireMemberId(id);
    return apiCall(() async {
      await _dio.put('${AppConstants.membersEndpoint}/$id', data: dto.toJson());
    });
  }

  Future<void> delete(int id) async {
    _requireMemberId(id);
    return apiCall(() async {
      await _dio.delete('${AppConstants.membersEndpoint}/$id');
    });
  }

  /// GET /api/Members/select — get members for selection dropdown
  Future<List<SelectOption>> getForSelection() async {
    return fetchSelectOptions(_dio, AppConstants.membersSelectEndpoint);
  }
}
