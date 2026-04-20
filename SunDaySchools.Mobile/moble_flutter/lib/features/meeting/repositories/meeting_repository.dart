import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/select_api.dart';
import '../../../core/constants/app_constants.dart';
import '../models/meeting_models.dart';
import '../../../core/models/select_option.dart';

class MeetingRepository {
  final Dio _dio;

  MeetingRepository(this._dio);

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
}
