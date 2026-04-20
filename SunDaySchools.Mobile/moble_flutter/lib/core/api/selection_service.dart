import 'package:dio/dio.dart';

import '../models/select_option.dart';
import 'dio_client.dart';

class SelectionService {
  final Dio _dio;

  const SelectionService(this._dio);

  Future<List<SelectOption>> fetchSelection(String endpoint) async {
    return apiCall(() async {
      final response = await _dio.get(endpoint);
      final list = response.data as List<dynamic>;
      return list
          .map((e) => SelectOption.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }
}

