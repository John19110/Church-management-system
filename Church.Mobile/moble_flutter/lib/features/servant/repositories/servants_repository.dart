import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/select_api.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/cache/cache_manager.dart';
import '../models/servant_models.dart';
import '../../../core/models/select_option.dart';
import '../../unified_form/models/unified_form_models.dart';

class ServantsRepository {
  final Dio _dio;
  final CacheManager _cache;

  ServantsRepository(this._dio, this._cache);

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

  Stream<List<ServantReadDto>> watchAllCacheFirst({
    required int tenantId,
    required String role,
  }) {
    final key = _cache.tenantRoleKey(tenantId, role, 'ministries_servants_all');
    return _cache.cacheFirstStream<List<ServantReadDto>>(
      key: key,
      ttl: const Duration(minutes: 15),
      fetch: getAll,
      toJson: (value) => {
        'items': value.map((e) => e.toJson()).toList(),
      },
      fromJson: (json) {
        final items = (json['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ServantReadDto.fromJson)
            .toList();
        return items;
      },
    );
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

  Stream<ServantProfileDto> watchProfileCacheFirst({
    required int tenantId,
    required String userId,
  }) {
    final key = _cache.tenantUserKey(tenantId, userId, 'user_profile');
    return _cache.cacheFirstStream<ServantProfileDto>(
      key: key,
      ttl: const Duration(minutes: 10),
      fetch: getProfile,
      toJson: (value) => value.toJson(),
      fromJson: ServantProfileDto.fromJson,
    );
  }

  Future<EntityFormDataDto> getProfileFormData() async {
    return apiCall(() async {
      final response = await _dio.get('${AppConstants.servantProfileEndpoint}/form-data');
      return EntityFormDataDto.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<void> saveProfileFormData(SaveEntityFormDto dto) async {
    return apiCall(() async {
      await _dio.put(
        '${AppConstants.servantProfileEndpoint}/form-data',
        data: dto.toJson(),
        options: Options(contentType: Headers.jsonContentType),
      );
    });
  }

  Future<ServantProfileDto?> updateProfile({
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
              filename: image.path.split(Platform.pathSeparator).last),
      };

      final ids = (classroomIds ?? const <int>[])
          .where((id) => id > 0)
          .toList();
      for (var i = 0; i < ids.length; i++) {
        map['ClassroomIds[$i]'] = ids[i].toString();
      }

      final response = await _dio.put(
        AppConstants.servantProfileEndpoint,
        data: FormData.fromMap(map),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ServantProfileDto.fromJson(data);
      }
      return null;
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

  /// GET /api/Meeting/{meetingId}/servants — servants belonging to a specific meeting.
  Future<List<ServantReadDto>> getByMeeting(int meetingId) async {
    return apiCall(() async {
      final response =
          await _dio.get(AppConstants.meetingServantsEndpoint(meetingId));
      final list = response.data as List<dynamic>;
      return list
          .map((e) => ServantReadDto.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Stream<List<ServantReadDto>> watchByMeetingCacheFirst({
    required int tenantId,
    required String role,
    required int meetingId,
  }) {
    final key =
        _cache.tenantRoleKey(tenantId, role, 'servant_list_meeting_$meetingId');
    return _cache.cacheFirstStream<List<ServantReadDto>>(
      key: key,
      ttl: const Duration(minutes: 5),
      fetch: () => getByMeeting(meetingId),
      toJson: (value) => {
        'items': value.map((e) => e.toJson()).toList(),
      },
      fromJson: (json) {
        final items = (json['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ServantReadDto.fromJson)
            .toList();
        return items;
      },
    );
  }

  /// GET /api/Servant/select — get servants for selection dropdown
  Future<List<SelectOption>> getForSelection() async {
    return fetchSelectOptions(_dio, AppConstants.servantsSelectEndpoint);
  }
}
