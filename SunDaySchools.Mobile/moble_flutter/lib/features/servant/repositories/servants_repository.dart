import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/select_api.dart';
import '../../../core/constants/app_constants.dart';
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

  Future<ServantProfileDto> getProfile() async {
    return apiCall(() async {
      final response = await _dio.get(AppConstants.servantProfileEndpoint);
      return ServantProfileDto.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<void> updateProfile({
    String? name,
    String? phoneNumber,
    String? birthDate,
    String? joiningDate,
    String? spiritualBirthDate,
    int? churchId,
    int? meetingId,
    List<int>? classroomIds,
    File? image,
  }) async {
    return apiCall(() async {
      final map = <String, dynamic>{
        if (name != null) 'Name': name,
        if (phoneNumber != null) 'PhoneNumber': phoneNumber,
        if (birthDate != null) 'BirthDate': birthDate,
        if (joiningDate != null) 'JoiningDate': joiningDate,
        if (spiritualBirthDate != null) 'SpiritualBirthDate': spiritualBirthDate,
        if (churchId != null) 'ChurchId': churchId.toString(),
        if (meetingId != null) 'MeetingId': meetingId.toString(),
        if (image != null)
          'Image': await MultipartFile.fromFile(image.path,
              filename: image.path.split('/').last),
      };

      final ids = (classroomIds ?? const <int>[])
          .where((id) => id > 0)
          .toList();
      for (var i = 0; i < ids.length; i++) {
        map['ClassroomIds[$i]'] = ids[i].toString();
      }

      await _dio.put(
        AppConstants.servantProfileEndpoint,
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
