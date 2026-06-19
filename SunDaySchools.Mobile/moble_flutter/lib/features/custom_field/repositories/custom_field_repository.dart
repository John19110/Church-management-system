import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
      final path = '${AppConstants.customFieldEndpoint}/definitions/$entityName';
      final queryParameters = {'includeInactive': includeInactive};

      debugPrint(
        '[CustomFieldRepository] GET $path includeInactive=$includeInactive',
      );

      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );

      debugPrint(
        '[CustomFieldRepository] status=${response.statusCode} '
        'bodyType=${response.data.runtimeType}',
      );

      final list = _parseDefinitionList(response.data);
      debugPrint(
        '[CustomFieldRepository] parsed ${list.length} definition(s) for $entityName',
      );

      final parsed = <CustomFieldDefinitionReadDto>[];
      for (var i = 0; i < list.length; i++) {
        try {
          final item = list[i];
          if (item is! Map<String, dynamic>) {
            debugPrint(
              '[CustomFieldRepository] skip index=$i: expected Map, got ${item.runtimeType}',
            );
            continue;
          }
          parsed.add(CustomFieldDefinitionReadDto.fromJson(item));
        } catch (e, st) {
          debugPrint(
            '[CustomFieldRepository] deserialize failed index=$i error=$e',
          );
          debugPrint(st.toString());
          rethrow;
        }
      }

      return parsed;
    });
  }

  List<dynamic> _parseDefinitionList(dynamic data) {
    if (data is List<dynamic>) return data;
    if (data is Map<String, dynamic>) {
      for (final key in const ['data', 'items', 'definitions', 'result']) {
        final nested = data[key];
        if (nested is List<dynamic>) return nested;
      }
    }
    debugPrint('[CustomFieldRepository] unexpected response shape: $data');
    return const [];
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

  Future<void> activateDefinition(int id) async {
    return apiCall(() async {
      await _dio.post(
        '${AppConstants.customFieldEndpoint}/definitions/$id/activate',
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
