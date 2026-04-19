import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/select_api.dart';
import '../../../core/constants/app_constants.dart';
import '../../../features/classroom/models/classroom_models.dart';
import '../models/servant_models.dart';
import '../../../core/models/select_option.dart';

class ServantsRepository {
  final Dio _dio;

  ServantsRepository(this._dio);

  void _requireServantId(int id) {
    if (id <= 0) {
      throw ArgumentError.value(
        id,
        'id',
        'Servant id must be a positive integer',
      );
    }
  }

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
    _requireServantId(id);
    return apiCall(() async {
      final response =
          await _dio.get('${AppConstants.servantEndpoint}/$id');
      return ServantReadDto.fromJson(response.data as Map<String, dynamic>);
    });
  }

  /// Create servant via admin endpoint:
  /// POST /Api/Admin/add-servant (multipart/form-data)
  /// The form includes both Account and Servant sub-object fields.
  Future<void> create({
    required String name,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    String? joiningDate,
    String? birthDate,
    List<int>? classroomsIds,
    File? image,
  }) async {
    return apiCall(() async {
      final map = <String, dynamic>{
        'Account.Name': name,
        'Account.PhoneNumber': phoneNumber,
        'Account.Password': password,
        'Account.ConfirmPassword': confirmPassword,
        if (birthDate != null) 'Account.BirthDate': birthDate,
        if (joiningDate != null) 'Account.JoiningDate': joiningDate,
        // AdminAddServantDTO wraps two sub-DTOs: Account and Servant.
        // Both receive dates/classrooms so the backend can populate each one.
        if (joiningDate != null) 'Servant.JoiningDate': joiningDate,
        if (birthDate != null) 'Servant.BirthDate': birthDate,
        if (image != null)
          'Servant.Image': await MultipartFile.fromFile(image.path,
              filename: image.path.split('/').last),
      };
      if (classroomsIds != null) {
        for (var i = 0; i < classroomsIds.length; i++) {
          map['Account.classroomsIds[$i]'] = classroomsIds[i].toString();
          map['Servant.classroomsIds[$i]'] = classroomsIds[i].toString();
        }
      }
      await _dio.post(
        '${AppConstants.adminEndpoint}/add-servant',
        data: FormData.fromMap(map),
      );
    });
  }

  /// Update servant: PUT /api/Servant/{id} (multipart/form-data)
  /// Matches ServantFormRequest: Name, JoiningDate, BirthDate, PhoneNumber, Image
  Future<void> update(
    int id, {
    String? name,
    String? phoneNumber,
    String? joiningDate,
    String? birthDate,
    int? classroomId,
    File? image,
  }) async {
    _requireServantId(id);
    return apiCall(() async {
      final map = <String, dynamic>{
        if (name != null) 'Name': name,
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
    _requireServantId(id);
    return apiCall(() async {
      await _dio.delete('${AppConstants.servantEndpoint}/$id');
    });
  }

  /// GET /api/Servant/select — get servants for selection dropdown
  Future<List<SelectOption>> getForSelection() async {
    return fetchSelectOptions(_dio, AppConstants.servantsSelectEndpoint);
  }
}
