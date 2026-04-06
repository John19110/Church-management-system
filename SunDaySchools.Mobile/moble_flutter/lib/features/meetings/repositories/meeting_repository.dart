import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../features/classrooms/models/classroom_models.dart';

class MeetingRepository {
  final Dio _dio;

  MeetingRepository(this._dio);

  /// GET /api/Meetings/select — get meetings for selection dropdown
  Future<List<SelectOptionDto>> getForSelection() async {
    return apiCall(() async {
      final response =
          await _dio.get('${AppConstants.meetingEndpoint}/select');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => SelectOptionDto.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// GET /api/Meetings/visible — triggers visible meetings retrieval
  Future<void> getVisibleMeetings() async {
    return apiCall(() async {
      await _dio.get('${AppConstants.meetingEndpoint}/visible');
    });
  }
}
