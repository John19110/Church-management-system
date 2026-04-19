import 'package:dio/dio.dart';

import '../models/select_option.dart';
import 'dio_client.dart';

Future<List<SelectOption>> fetchSelectOptions(Dio dio, String endpoint) async {
  return apiCall(() async {
    final response = await dio.get(endpoint);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => SelectOption.fromJson(e as Map<String, dynamic>))
        .toList();
  });
}

