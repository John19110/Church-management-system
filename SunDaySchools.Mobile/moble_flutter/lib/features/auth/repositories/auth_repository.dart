import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  /// Login: POST Api/Account/Login — response body is raw JWT string
  Future<String> login(LoginDto dto) async {
    return apiCall(() async {
      final response = await _dio.post(
        AppConstants.loginEndpoint,
        data: dto.toJson(),
      );
      final token = response.data as String;
      await TokenStorage.saveToken(token);
      return token;
    });
  }

  /// Register: POST Api/Account/Register — multipart/form-data, response body is raw JWT string
  Future<String> register(RegisterDto dto) async {
    return apiCall(() async {
      final formData = FormData.fromMap({
        'Name': dto.name,
        'PhoneNumber': dto.phoneNumber,
        'Password': dto.password,
        'ConfirmPassword': dto.confirmPassword,
      });
      final response = await _dio.post(
        AppConstants.registerEndpoint,
        data: formData,
      );
      final token = response.data as String;
      await TokenStorage.saveToken(token);
      return token;
    });
  }

  Future<void> logout() async {
    await TokenStorage.deleteToken();
  }
}
