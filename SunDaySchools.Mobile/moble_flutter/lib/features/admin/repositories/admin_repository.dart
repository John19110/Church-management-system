import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/constants/app_constants.dart';
import '../models/admin_models.dart';

class AdminRepository {
  final Dio _dio;

  AdminRepository(this._dio);

  /// GET /Api/Admin/pending-servants — list servants awaiting approval
  Future<List<PendingUserDto>> getPendingServants() async {
    return apiCall(() async {
      final response = await _dio
          .get('${AppConstants.adminEndpoint}/pending-servants');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => PendingUserDto.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// PUT /Api/Admin/assign-class/{servantId}/{classroomId}
  Future<void> assignClass(int servantId, int classroomId) async {
    return apiCall(() async {
      await _dio.put(
          '${AppConstants.adminEndpoint}/assign-class/$servantId/$classroomId');
    });
  }

  /// PUT /Api/Admin/approve-servant/{userId}
  Future<void> approveServant(String userId) async {
    return apiCall(() async {
      await _dio
          .put('${AppConstants.adminEndpoint}/approve-servant/$userId');
    });
  }

  /// DELETE /Api/Admin/reject-servant/{userId}
  Future<void> rejectServant(String userId) async {
    return apiCall(() async {
      await _dio
          .delete('${AppConstants.adminEndpoint}/reject-servant/$userId');
    });
  }
}
