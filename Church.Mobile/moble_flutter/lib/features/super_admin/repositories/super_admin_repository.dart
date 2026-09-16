import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/constants/app_constants.dart';
import '../models/super_admin_models.dart';

class SuperAdminRepository {
  final Dio _dio;

  SuperAdminRepository(this._dio);

  /// POST /api/Meeting — create a new meeting (SuperAdmin role required)
  Future<void> createMeeting(MeetingAddDto dto) async {
    return apiCall(() async {
      await _dio.post(
        AppConstants.meetingEndpoint,
        data: dto.toJson(),
      );
    });
  }

  /// GET /api/SuperAdmin/pending-admins — list admins awaiting approval
  Future<List<PendingUserDto>> getPendingAdmins() async {
    return apiCall(() async {
      final response = await _dio
          .get('${AppConstants.superAdminEndpoint}/pending-admins');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => PendingUserDto.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// POST /api/super-admin/admins/{userId}/approve
  Future<void> approveAdmin(String userId) async {
    return apiCall(() async {
      await _dio.post(
          '${AppConstants.superAdminEndpoint}/admins/$userId/approve');
    });
  }

  /// POST /api/super-admin/admins/{userId}/reject
  Future<void> rejectAdmin(String userId) async {
    return apiCall(() async {
      await _dio.post(
          '${AppConstants.superAdminEndpoint}/admins/$userId/reject');
    });
  }

  // ---- Church user approval workflow ----

  /// GET /api/SuperAdmin/pending-users — all pending users in this church.
  Future<List<PendingChurchUserDto>> getPendingUsers() async {
    return apiCall(() async {
      final response = await _dio
          .get('${AppConstants.superAdminEndpoint}/pending-users');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => PendingChurchUserDto.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// POST /api/super-admin/users/{userId}/approve
  Future<void> approveUser(String userId, {int? meetingId}) async {
    return apiCall(() async {
      await _dio.post(
        '${AppConstants.superAdminEndpoint}/users/$userId/approve',
        data: {'meetingId': meetingId},
      );
    });
  }

  /// POST /api/super-admin/users/{userId}/reject
  Future<void> rejectUser(String userId, {String? reason}) async {
    return apiCall(() async {
      await _dio.post(
        '${AppConstants.superAdminEndpoint}/users/$userId/reject',
        data: {'reason': reason},
      );
    });
  }
}
