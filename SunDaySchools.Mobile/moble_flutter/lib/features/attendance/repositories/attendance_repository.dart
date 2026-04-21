import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/constants/app_constants.dart';
import '../models/attendance_models.dart';

class AttendanceRepository {
  final Dio _dio;

  AttendanceRepository(this._dio);

  Future<void> create(AttendanceSessionAddDto dto) async {
    return apiCall(() async {
      await _dio.post(AppConstants.attendanceEndpoint, data: dto.toJson());
    });
  }

  Future<AttendanceSessionReadDto> getById(int sessionId) async {
    return apiCall(() async {
      final response =
          await _dio.get('${AppConstants.attendanceEndpoint}/$sessionId');
      return AttendanceSessionReadDto.fromJson(
          response.data as Map<String, dynamic>);
    });
  }

  Future<void> update(int id, AttendanceSessionUpdateDto dto) async {
    return apiCall(() async {
      await _dio.put(
          '${AppConstants.attendanceEndpoint}/$id', data: dto.toJson());
    });
  }

  Future<List<AttendanceSessionSummaryDto>> getHistoryByClassroom(
      int classroomId) async {
    return apiCall(() async {
      final response = await _dio.get(
        '${AppConstants.attendanceByClassroomEndpoint}/$classroomId',
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) =>
              AttendanceSessionSummaryDto.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }
}
