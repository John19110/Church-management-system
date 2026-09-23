import 'package:dio/dio.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/constants/app_constants.dart';
import '../models/custom_feature_models.dart';

class CustomFeatureRepository {
  final Dio _dio;

  CustomFeatureRepository(this._dio);

  Future<List<CustomFeatureReadDto>> getFeatures({
    bool includeInactive = false,
  }) async {
    return apiCall(() async {
      final response = await _dio.get(
        AppConstants.customFeaturesEndpoint,
        queryParameters: {'includeInactive': includeInactive},
      );
      final list = response.data as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(CustomFeatureReadDto.fromJson)
          .toList();
    });
  }

  Future<CustomFeatureReadDto> getFeature(int id) async {
    return apiCall(() async {
      final response =
          await _dio.get('${AppConstants.customFeaturesEndpoint}/$id');
      return CustomFeatureReadDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  Future<CustomFeatureReadDto> createFeature({
    required String displayName,
    String? displayNameAr,
  }) async {
    return apiCall(() async {
      final response = await _dio.post(
        AppConstants.customFeaturesEndpoint,
        data: {
          'displayName': displayName,
          if (displayNameAr != null) 'displayNameAr': displayNameAr,
        },
      );
      return CustomFeatureReadDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  Future<CustomFeatureReadDto> updateFeature({
    required int id,
    required String displayName,
    String? displayNameAr,
    bool? isActive,
  }) async {
    return apiCall(() async {
      final response = await _dio.put(
        '${AppConstants.customFeaturesEndpoint}/$id',
        data: {
          'displayName': displayName,
          'displayNameAr': displayNameAr,
          if (isActive != null) 'isActive': isActive,
        },
      );
      return CustomFeatureReadDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  Future<void> deleteFeature(int id) async {
    return apiCall(() async {
      await _dio.delete('${AppConstants.customFeaturesEndpoint}/$id');
    });
  }

  Future<List<CustomEntityReadDto>> getEntities(
    int featureId, {
    bool includeInactive = false,
  }) async {
    return apiCall(() async {
      final response = await _dio.get(
        '${AppConstants.customFeaturesEndpoint}/$featureId/entities',
        queryParameters: {'includeInactive': includeInactive},
      );
      final list = response.data as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(CustomEntityReadDto.fromJson)
          .toList();
    });
  }

  Future<CustomEntityReadDto> getEntity(int id) async {
    return apiCall(() async {
      final response =
          await _dio.get('${AppConstants.customEntitiesEndpoint}/$id');
      return CustomEntityReadDto.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<CustomEntityReadDto> createEntity({
    required int featureId,
    required String displayName,
    String? displayNameAr,
    String? pluralDisplayName,
    String? pluralDisplayNameAr,
  }) async {
    return apiCall(() async {
      final response = await _dio.post(
        '${AppConstants.customFeaturesEndpoint}/$featureId/entities',
        data: {
          'displayName': displayName,
          if (displayNameAr != null) 'displayNameAr': displayNameAr,
          if (pluralDisplayName != null) 'pluralDisplayName': pluralDisplayName,
          if (pluralDisplayNameAr != null)
            'pluralDisplayNameAr': pluralDisplayNameAr,
        },
      );
      return CustomEntityReadDto.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<CustomEntityReadDto> updateEntity({
    required int id,
    required String displayName,
    String? displayNameAr,
    required String pluralDisplayName,
    String? pluralDisplayNameAr,
    bool? isActive,
  }) async {
    return apiCall(() async {
      final response = await _dio.put(
        '${AppConstants.customEntitiesEndpoint}/$id',
        data: {
          'displayName': displayName,
          'displayNameAr': displayNameAr,
          'pluralDisplayName': pluralDisplayName,
          'pluralDisplayNameAr': pluralDisplayNameAr,
          if (isActive != null) 'isActive': isActive,
        },
      );
      return CustomEntityReadDto.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<void> deleteEntity(int id) async {
    return apiCall(() async {
      await _dio.delete('${AppConstants.customEntitiesEndpoint}/$id');
    });
  }

  Future<CustomEntityFieldReadDto> createField({
    required int entityId,
    required Map<String, dynamic> body,
  }) async {
    return apiCall(() async {
      final response = await _dio.post(
        '${AppConstants.customEntitiesEndpoint}/$entityId/fields',
        data: body,
      );
      return CustomEntityFieldReadDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  Future<CustomEntityFieldReadDto> updateField({
    required int id,
    required Map<String, dynamic> body,
  }) async {
    return apiCall(() async {
      final response = await _dio.put(
        '${AppConstants.customEntitiesEndpoint}/fields/$id',
        data: body,
      );
      return CustomEntityFieldReadDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  Future<void> deleteField(int id) async {
    return apiCall(() async {
      await _dio.delete('${AppConstants.customEntitiesEndpoint}/fields/$id');
    });
  }

  Future<List<CustomEntityPermissionDto>> updatePermissions({
    required int entityId,
    required List<CustomEntityPermissionDto> permissions,
  }) async {
    return apiCall(() async {
      final response = await _dio.put(
        '${AppConstants.customEntitiesEndpoint}/$entityId/permissions',
        data: permissions.map((p) => p.toJson()).toList(),
      );
      final list = response.data as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(CustomEntityPermissionDto.fromJson)
          .toList();
    });
  }

  Future<CustomEntityRecordPageDto> getRecords({
    required int entityId,
    String? search,
    String? sort,
    bool descending = true,
    int page = 1,
    int pageSize = 20,
  }) async {
    return apiCall(() async {
      final response = await _dio.get(
        '${AppConstants.customEntitiesEndpoint}/$entityId/records',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (sort != null && sort.isNotEmpty) 'sort': sort,
          'descending': descending,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return CustomEntityRecordPageDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  Future<CustomEntityRecordReadDto> getRecord({
    required int entityId,
    required int recordId,
  }) async {
    return apiCall(() async {
      final response = await _dio.get(
        '${AppConstants.customEntitiesEndpoint}/$entityId/records/$recordId',
      );
      return CustomEntityRecordReadDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  Future<CustomEntityRecordReadDto> saveRecord({
    required int entityId,
    int? recordId,
    required Map<String, dynamic> values,
  }) async {
    return apiCall(() async {
      final path = recordId == null
          ? '${AppConstants.customEntitiesEndpoint}/$entityId/records'
          : '${AppConstants.customEntitiesEndpoint}/$entityId/records/$recordId';
      final response = recordId == null
          ? await _dio.post(path, data: {'values': values})
          : await _dio.put(path, data: {'values': values});
      return CustomEntityRecordReadDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  Future<void> deleteRecord({
    required int entityId,
    required int recordId,
  }) async {
    return apiCall(() async {
      await _dio.delete(
        '${AppConstants.customEntitiesEndpoint}/$entityId/records/$recordId',
      );
    });
  }
}
