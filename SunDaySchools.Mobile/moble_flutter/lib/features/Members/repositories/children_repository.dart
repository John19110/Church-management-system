import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../features/classrooms/models/classroom_models.dart';
import '../models/child_models.dart';

class ChildrenRepository {
  final Dio _dio;

  ChildrenRepository(this._dio);

  Future<List<ChildReadDto>> getAll() async {
    return apiCall(() async {
      final response = await _dio.get(AppConstants.membersEndpoint);
      final list = response.data as List<dynamic>;
      return list.map((e) => ChildReadDto.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<List<ChildReadDto>> getByClassroom(int classroomId) async {
    return apiCall(() async {
      final response = await _dio.get(
        '${AppConstants.membersEndpoint}/classroom/$classroomId',
      );
      final list = response.data as List<dynamic>;
      return list.map((e) => ChildReadDto.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<ChildReadDto> getById(int id) async {
    return apiCall(() async {
      final response = await _dio.get('${AppConstants.membersEndpoint}/$id');
      return ChildReadDto.fromJson(response.data as Map<String, dynamic>);
    });
  }

  /// Create member: POST /api/classrooms/{classroomId}/members (multipart/form-data)
  /// [classroomId] is passed as a URL path parameter.
  Future<void> create(int classroomId, ChildAddDto dto, {File? image}) async {
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
  Future<void> update(int id, ChildUpdateDto dto) async {
    return apiCall(() async {
      await _dio.put('${AppConstants.membersEndpoint}/$id', data: dto.toJson());
    });
  }

  Future<void> delete(int id) async {
    return apiCall(() async {
      await _dio.delete('${AppConstants.membersEndpoint}/$id');
    });
  }

  /// GET /api/Members/select — get members for selection dropdown
  Future<List<SelectOptionDto>> getForSelection() async {
    return apiCall(() async {
      final response =
          await _dio.get('${AppConstants.membersEndpoint}/select');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => SelectOptionDto.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }
}
