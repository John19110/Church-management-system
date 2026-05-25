import 'package:dio/dio.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/constants/app_constants.dart';

import '../models/unified_form_models.dart';

class UnifiedFormRepository {
  final Dio _dio;

  UnifiedFormRepository(this._dio);

  String _entityBase(String entityName) {
    switch (entityName) {
      case UnifiedEntityNames.member:
        return AppConstants.membersEndpoint;
      case UnifiedEntityNames.classroom:
        return AppConstants.classroomEndpoint;
      case UnifiedEntityNames.servant:
        return AppConstants.servantEndpoint;
      case UnifiedEntityNames.meeting:
        return AppConstants.meetingEndpoint;
      default:
        throw ArgumentError('Unsupported entity: $entityName');
    }
  }

  Future<EntityFormSchemaDto> getFormSchema(
    String entityName, {
    String mode = 'Edit',
  }) async {
    return apiCall(() async {
      final response = await _dio.get(
        '${_entityBase(entityName)}/form-schema',
        queryParameters: {'mode': mode},
      );
      return EntityFormSchemaDto.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<EntityFormDataDto> getFormData(String entityName, int entityId) async {
    return apiCall(() async {
      final response = await _dio.get(
        '${_entityBase(entityName)}/$entityId/form-data',
      );
      return EntityFormDataDto.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<void> saveFormData(
    String entityName,
    int entityId,
    SaveEntityFormDto dto,
  ) async {
    return apiCall(() async {
      await _dio.put(
        '${_entityBase(entityName)}/$entityId/form-data',
        data: dto.toJson(),
        options: Options(contentType: Headers.jsonContentType),
      );
    });
  }

  /// Creates entity from admin-defined fields only; returns new entity id.
  Future<int> createFromForm(
    String entityName,
    SaveEntityFormDto dto, {
    int? classroomIdForMember,
  }) async {
    return apiCall(() async {
      final response = await _dio.post(
        '${_entityBase(entityName)}/create-from-form',
        data: dto.toJson(),
        queryParameters: classroomIdForMember != null
            ? {'classroomId': classroomIdForMember}
            : null,
        options: Options(contentType: Headers.jsonContentType),
      );
      final data = response.data as Map<String, dynamic>;
      return data['id'] as int;
    });
  }
}
