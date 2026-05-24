import 'package:dio/dio.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/constants/app_constants.dart';
import '../models/custom_field_models.dart';

class CustomFieldRepository {
  final Dio _dio;

  CustomFieldRepository(this._dio);

  Future<List<CustomFieldDefinitionReadDto>> getDefinitions(
    String entityName, {
    bool includeInactive = false,
  }) async {
    return apiCall(() async {
      final response = await _dio.get(
        '${AppConstants.customFieldEndpoint}/definitions/$entityName',
        queryParameters: {'includeInactive': includeInactive},
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) =>
              CustomFieldDefinitionReadDto.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<CustomFieldDefinitionReadDto> createDefinition(
    CustomFieldDefinitionCreateDto dto,
  ) async {
    return apiCall(() async {
      final response = await _dio.post(
        '${AppConstants.customFieldEndpoint}/definitions',
        data: dto.toJson(),
        options: Options(contentType: Headers.jsonContentType),
      );
      return CustomFieldDefinitionReadDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  Future<CustomFieldDefinitionReadDto> updateDefinition(
    int id,
    CustomFieldDefinitionUpdateDto dto,
  ) async {
    return apiCall(() async {
      final response = await _dio.put(
        '${AppConstants.customFieldEndpoint}/definitions/$id',
        data: dto.toJson(),
        options: Options(contentType: Headers.jsonContentType),
      );
      return CustomFieldDefinitionReadDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  Future<void> deactivateDefinition(int id) async {
    return apiCall(() async {
      await _dio.post(
        '${AppConstants.customFieldEndpoint}/definitions/$id/deactivate',
      );
    });
  }

  Future<EntityCustomFieldsReadDto> getEntityFields(
    String entityName,
    int entityId,
  ) async {
    return apiCall(() async {
      final response = await _dio.get(
        '${AppConstants.customFieldEndpoint}/entities/$entityName/$entityId',
      );
      return EntityCustomFieldsReadDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  Future<void> saveValues({
    required String entityName,
    required int entityId,
    required List<CustomFieldValueItemDto> values,
  }) async {
    return apiCall(() async {
      await _dio.put(
        '${AppConstants.customFieldEndpoint}/values',
        data: {
          'entityName': entityName,
          'entityId': entityId,
          'values': values.map((v) => v.toJson()).toList(),
        },
        options: Options(contentType: Headers.jsonContentType),
      );
    });
  }
}
