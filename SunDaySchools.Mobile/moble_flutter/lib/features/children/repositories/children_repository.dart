import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/constants/app_constants.dart';
import '../models/child_models.dart';

class ChildrenRepository {
  final Dio _dio;

  ChildrenRepository(this._dio);

  Future<List<ChildReadDto>> getAll() async {
    return apiCall(() async {
      final response = await _dio.get(AppConstants.childrenEndpoint);
      final list = response.data as List<dynamic>;
      return list.map((e) => ChildReadDto.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<List<ChildReadDto>> getByClassroom(int classroomId) async {
    return apiCall(() async {
      final response = await _dio.get(
        '${AppConstants.childrenEndpoint}/classroom/$classroomId',
      );
      final list = response.data as List<dynamic>;
      return list.map((e) => ChildReadDto.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<ChildReadDto> getById(int id) async {
    return apiCall(() async {
      final response = await _dio.get('${AppConstants.childrenEndpoint}/$id');
      return ChildReadDto.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<void> create(ChildAddDto dto) async {
    return apiCall(() async {
      await _dio.post(AppConstants.childrenEndpoint, data: dto.toJson());
    });
  }

  Future<void> update(int id, ChildUpdateDto dto) async {
    return apiCall(() async {
      await _dio.put('${AppConstants.childrenEndpoint}/$id', data: dto.toJson());
    });
  }

  Future<void> delete(int id) async {
    return apiCall(() async {
      await _dio.delete('${AppConstants.childrenEndpoint}/$id');
    });
  }
}
