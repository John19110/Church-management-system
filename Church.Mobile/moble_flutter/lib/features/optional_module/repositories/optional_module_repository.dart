import 'package:dio/dio.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/media/picked_image.dart';
import '../models/optional_module_models.dart';

class OptionalModuleRepository {
  final Dio _dio;

  OptionalModuleRepository(this._dio);

  Future<List<OptionalModuleDto>> getModules() async {
    return apiCall(() async {
      final response = await _dio.get(AppConstants.optionalModulesEndpoint);
      final list = response.data as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(OptionalModuleDto.fromJson)
          .toList();
    });
  }

  Future<OptionalModuleDto> setEnabled({
    required String moduleId,
    required bool isEnabled,
  }) async {
    return apiCall(() async {
      final response = await _dio.put(
        '${AppConstants.optionalModulesEndpoint}/$moduleId/enabled',
        data: {'isEnabled': isEnabled},
      );
      return OptionalModuleDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }
}

class StockItemRepository {
  final Dio _dio;

  StockItemRepository(this._dio);

  Future<List<StockItemDto>> getItems({String? search}) async {
    return apiCall(() async {
      final response = await _dio.get(
        AppConstants.stockItemsEndpoint,
        queryParameters: {
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );
      final list = response.data as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(StockItemDto.fromJson)
          .toList();
    });
  }

  Future<StockItemDto> getItem(int id) async {
    return apiCall(() async {
      final response =
          await _dio.get('${AppConstants.stockItemsEndpoint}/$id');
      return StockItemDto.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<StockItemDto> createItem({
    required String name,
    String? nameAr,
    String? description,
    String? descriptionAr,
    required int amount,
  }) async {
    return apiCall(() async {
      final response = await _dio.post(
        AppConstants.stockItemsEndpoint,
        data: {
          'name': name,
          'nameAr': nameAr,
          'description': description,
          'descriptionAr': descriptionAr,
          'amount': amount,
        },
      );
      return StockItemDto.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<StockItemDto> updateItem({
    required int id,
    required String name,
    String? nameAr,
    String? description,
    String? descriptionAr,
    required int amount,
  }) async {
    return apiCall(() async {
      final response = await _dio.put(
        '${AppConstants.stockItemsEndpoint}/$id',
        data: {
          'name': name,
          'nameAr': nameAr,
          'description': description,
          'descriptionAr': descriptionAr,
          'amount': amount,
        },
      );
      return StockItemDto.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<void> deleteItem(int id) async {
    return apiCall(() async {
      await _dio.delete('${AppConstants.stockItemsEndpoint}/$id');
    });
  }

  Future<StockAmountChangeResult> increase(int id) async {
    return apiCall(() async {
      final response =
          await _dio.post('${AppConstants.stockItemsEndpoint}/$id/increase');
      return StockAmountChangeResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  Future<StockAmountChangeResult> decrease(int id) async {
    return apiCall(() async {
      final response =
          await _dio.post('${AppConstants.stockItemsEndpoint}/$id/decrease');
      return StockAmountChangeResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    });
  }

  Future<StockItemDto> uploadImage(int id, PickedImage image) async {
    return apiCall(() async {
      final form = FormData.fromMap({
        'image': image.toMultipartFile(),
      });
      final response = await _dio.post(
        '${AppConstants.stockItemsEndpoint}/$id/image',
        data: form,
      );
      return StockItemDto.fromJson(response.data as Map<String, dynamic>);
    });
  }
}
