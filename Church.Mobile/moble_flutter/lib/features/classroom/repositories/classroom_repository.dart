import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/select_api.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/cache/cache_manager.dart';
import '../models/classroom_models.dart';
import '../../../core/models/select_option.dart';

class ClassroomRepository {
  final Dio _dio;
  final CacheManager _cache;

  ClassroomRepository(this._dio, this._cache);

  /// GET /classrooms/select — returns {id, name} list
  Future<List<SelectOption>> getForSelection() async {
    return fetchSelectOptions(_dio, AppConstants.classroomsSelectEndpoint);
  }

  /// GET /api/Classroom/visible — returns visible classrooms
  Future<List<ClassroomReadDto>> getVisible({int? meetingId}) async {
    return apiCall(() async {
      final response = await _dio.get(
        '${AppConstants.classroomEndpoint}/visible',
        queryParameters: {
          if (meetingId != null) 'meetingId': meetingId,
        },
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => ClassroomReadDto.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Stream<List<ClassroomReadDto>> watchVisibleCacheFirst({
    required int tenantId,
    required String role,
    int? meetingId,
  }) {
    final key = _cache.tenantRoleKey(
      tenantId,
      role,
      'dashboard_visible_classrooms_meeting_${meetingId ?? "all"}',
    );
    return _cache.cacheFirstStream<List<ClassroomReadDto>>(
      key: key,
      ttl: const Duration(minutes: 5),
      fetch: () => getVisible(meetingId: meetingId),
      toJson: (value) => {
        'items': value.map((e) => e.toJson()).toList(),
      },
      fromJson: (json) {
        final items = (json['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ClassroomReadDto.fromJson)
            .toList();
        return items;
      },
    );
  }

  /// POST /api/Classroom — add a new classroom
  Future<void> add(ClassroomAddDto dto) async {
    return apiCall(() async {
      await _dio.post(AppConstants.classroomEndpoint, data: dto.toJson());
    });
  }

  /// DELETE /api/Classroom/{id}
  Future<void> delete(int id) async {
    if (id <= 0) {
      throw ArgumentError.value(id, 'id', 'Classroom id must be a positive integer');
    }
    return apiCall(() async {
      await _dio.delete('${AppConstants.classroomEndpoint}/$id');
    });
  }
}
