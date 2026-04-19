import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/select_api.dart';
import '../../../core/constants/app_constants.dart';
import '../../../features/classroom/models/classroom_models.dart';
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
}
