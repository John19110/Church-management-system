import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/select_api.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/cache/cache_manager.dart';
import '../models/meeting_models.dart';
import '../../../core/models/select_option.dart';

class MeetingRepository {
  final Dio _dio;
  final CacheManager _cache;

  MeetingRepository(this._dio, this._cache);

  /// GET /api/Meeting/select — get meetings for selection dropdown
  Future<List<SelectOption>> getForSelection() async {
    return fetchSelectOptions(_dio, AppConstants.meetingsSelectEndpoint);
  }

  /// GET /api/Meeting/visible — returns visible meetings
  Future<List<MeetingReadDto>> getVisibleMeetings() async {
    return apiCall(() async {
      final response = await _dio.get('${AppConstants.meetingEndpoint}/visible');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => MeetingReadDto.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// Cache-first: emits cached meetings immediately, refreshes in background.
  Stream<List<MeetingReadDto>> watchVisibleMeetingsCacheFirst({
    required int tenantId,
    required String role,
  }) {
    final key = _cache.tenantRoleKey(tenantId, role, 'events_visible_meetings');
    return _cache.cacheFirstStream<List<MeetingReadDto>>(
      key: key,
      ttl: const Duration(minutes: 5),
      fetch: getVisibleMeetings,
      toJson: (value) => {
        'items': value.map((e) => e.toJson()).toList(),
      },
      fromJson: (json) {
        final items = (json['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(MeetingReadDto.fromJson)
            .toList();
        return items;
      },
    );
  }

  /// PUT /api/Meeting/{id} — update meeting (currently supports LeaderServantId)
  Future<void> update(int id, {int? leaderServantId}) async {
    if (id <= 0) {
      throw ArgumentError.value(id, 'id', 'Meeting id must be a positive integer');
    }
    return apiCall(() async {
      await _dio.put(
        '${AppConstants.meetingEndpoint}/$id',
        data: {
          'leaderServantId': leaderServantId,
        },
      );
    });
  }

  /// DELETE /api/Meeting/{id}
  Future<void> delete(int id) async {
    if (id <= 0) {
      throw ArgumentError.value(id, 'id', 'Meeting id must be a positive integer');
    }
    return apiCall(() async {
      await _dio.delete('${AppConstants.meetingEndpoint}/$id');
    });
  }
}
