import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/constants/app_constants.dart';
import '../models/servant_models.dart';

class ServantsRepository {
  final Dio _dio;

  ServantsRepository(this._dio);

  Future<List<ServantReadDto>> getAll() async {
    return apiCall(() async {
      final response = await _dio.get(AppConstants.servantEndpoint);
      final list = response.data as List<dynamic>;
      return list
          .map((e) => ServantReadDto.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<ServantReadDto> getById(int id) async {
    return apiCall(() async {
      final response =
          await _dio.get('${AppConstants.servantEndpoint}/$id');
      return ServantReadDto.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<void> create({
    required String name,
    required String applicationUserId,
    String? phoneNumber,
    String? joiningDate,
    String? birthDate,
    int? classroomId,
    File? image,
  }) async {
    return apiCall(() async {
      final map = <String, dynamic>{
        'Name': name,
        'ApplicationUserId': applicationUserId,
        if (phoneNumber != null) 'PhoneNumber': phoneNumber,
        if (joiningDate != null) 'JoiningDate': joiningDate,
        if (birthDate != null) 'BirthDate': birthDate,
        if (classroomId != null) 'ClassroomId': classroomId.toString(),
        if (image != null)
          'Image': await MultipartFile.fromFile(image.path,
              filename: image.path.split('/').last),
      };
      await _dio.post(
        AppConstants.servantEndpoint,
        data: FormData.fromMap(map),
      );
    });
  }

  Future<void> update(
    int id, {
    required String name,
    required String applicationUserId,
    String? phoneNumber,
    String? joiningDate,
    String? birthDate,
    int? classroomId,
    File? image,
  }) async {
    return apiCall(() async {
      final map = <String, dynamic>{
        'Name': name,
        'ApplicationUserId': applicationUserId,
        if (phoneNumber != null) 'PhoneNumber': phoneNumber,
        if (joiningDate != null) 'JoiningDate': joiningDate,
        if (birthDate != null) 'BirthDate': birthDate,
        if (classroomId != null) 'ClassroomId': classroomId.toString(),
        if (image != null)
          'Image': await MultipartFile.fromFile(image.path,
              filename: image.path.split('/').last),
      };
      await _dio.put(
        '${AppConstants.servantEndpoint}/$id',
        data: FormData.fromMap(map),
      );
    });
  }

  Future<void> delete(int id) async {
    return apiCall(() async {
      await _dio.delete('${AppConstants.servantEndpoint}/$id');
    });
  }
}
