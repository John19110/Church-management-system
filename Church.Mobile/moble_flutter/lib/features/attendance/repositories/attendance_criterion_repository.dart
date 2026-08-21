import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/constants/app_constants.dart';
import '../models/attendance_criterion_models.dart';

class AttendanceCriterionRepository {
  final Dio _dio;

  AttendanceCriterionRepository(this._dio);

  Future<List<AttendanceCriterionDto>> getByMeeting(
    int meetingId, {
    bool includeInactive = false,
  }) async {
    return apiCall(() async {
      final response = await _dio.get(
        AppConstants.meetingAttendanceCriteriaEndpoint(meetingId),
        queryParameters: {
          if (includeInactive) 'includeInactive': true,
        },
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) =>
              AttendanceCriterionDto.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<AttendanceCriterionDto> create(
    int meetingId, {
    required String displayName,
    String? displayNameAr,
    int? sortOrder,
  }) async {
    return apiCall(() async {
      final response = await _dio.post(
        AppConstants.meetingAttendanceCriteriaEndpoint(meetingId),
        data: {
          'displayName': displayName,
          if (displayNameAr != null) 'displayNameAr': displayNameAr,
          if (sortOrder != null) 'sortOrder': sortOrder,
        },
      );
      return AttendanceCriterionDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  Future<AttendanceCriterionDto> update(
    int id, {
    required String displayName,
    String? displayNameAr,
    required bool isActive,
    required int sortOrder,
  }) async {
    return apiCall(() async {
      final response = await _dio.put(
        AppConstants.attendanceCriterionEndpoint(id),
        data: {
          'displayName': displayName,
          if (displayNameAr != null) 'displayNameAr': displayNameAr,
          'isActive': isActive,
          'sortOrder': sortOrder,
        },
      );
      return AttendanceCriterionDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  Future<void> softDelete(int id) async {
    return apiCall(() async {
      await _dio.delete(AppConstants.attendanceCriterionEndpoint(id));
    });
  }

  Future<void> reorder(int meetingId, List<int> orderedIds) async {
    return apiCall(() async {
      await _dio.put(
        AppConstants.meetingAttendanceCriteriaReorderEndpoint(meetingId),
        data: {'orderedIds': orderedIds},
      );
    });
  }
}
