import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/constants/app_constants.dart';
import '../models/classroom_models.dart';

class ClassroomRepository {
  final Dio _dio;

  ClassroomRepository(this._dio);

  /// GET /api/Classroom/visible — returns visible classrooms
  Future<List<ClassroomReadDto>> getVisible() async {
    return apiCall(() async {
      final response =
          await _dio.get('${AppConstants.classroomEndpoint}/visible');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => ClassroomReadDto.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// POST /api/Classroom — add a new classroom
  Future<void> add(ClassroomAddDto dto) async {
    return apiCall(() async {
      await _dio.post(AppConstants.classroomEndpoint, data: dto.toJson());
    });
  }
}
