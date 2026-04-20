import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/constants/app_constants.dart';
import '../models/admin_models.dart';

class AdminRepository {
  final Dio _dio;

  AdminRepository(this._dio);

  /// POST /Api/Admin/add-servant (multipart/form-data)
  /// Adds a servant along with their account credentials.
  Future<void> addServant(AdminAddServantDto dto, {File? image}) async {
    return apiCall(() async {
      final classroomsIds = (dto.classroomsIds ?? const <int>[])
          .where((id) => id > 0)
          .toList();
      if (classroomsIds.isEmpty) {
        throw ArgumentError('classroomsIds is required and cannot be empty.');
      }

      final map = <String, dynamic>{
        'Account.Name': dto.accountName,
        'Account.PhoneNumber': dto.phoneNumber,
        'Account.Password': dto.password,
        'Account.ConfirmPassword': dto.confirmPassword,
        if (dto.birthDate != null) 'Account.BirthDate': dto.birthDate,
        if (dto.joiningDate != null) 'Account.JoiningDate': dto.joiningDate,
        if (dto.servantBirthDate != null)
          'Servant.BirthDate': dto.servantBirthDate,
        if (dto.servantJoiningDate != null)
          'Servant.JoiningDate': dto.servantJoiningDate,
        if (image != null)
          'Servant.Image': await MultipartFile.fromFile(image.path,
              filename: image.path.split('/').last),
      };
      for (var i = 0; i < classroomsIds.length; i++) {
        map['Account.classroomsIds[$i]'] = classroomsIds[i];
        map['Servant.classroomsIds[$i]'] = classroomsIds[i];
      }

      // Debug log: ensure classroomsIds exists in the outgoing payload.
      // (Endpoint + ids only; do not print passwords.)
      // ignore: avoid_print
      print('[add-servant] POST ${AppConstants.adminEndpoint}/add-servant '
          'classroomsIds=$classroomsIds image=${image != null}');
      await _dio.post(
        '${AppConstants.adminEndpoint}/add-servant',
        data: FormData.fromMap(map),
        options: Options(contentType: 'multipart/form-data'),
      );
    });
  }

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
