import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/storage/token_storage.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  /// Login: POST /api/Account/login
  /// Response body: { "token": "<jwt>" }
  Future<String> login(LoginDto dto) async {
    return apiCall(() async {
      final response = await _dio.post(
        AppConstants.loginEndpoint,
        data: dto.toJson(),
      );
      final token =
          (response.data as Map<String, dynamic>)['token'] as String;
      await TokenStorage.saveToken(token);
      return token;
    });
  }

  /// Servant self-registration: POST /api/Account/register-servant
  /// Multipart/form-data — response body: { "token": "<jwt>" }
  Future<String> registerServant(RegisterServantDto dto) async {
    return apiCall(() async {
      final map = <String, dynamic>{
        'Name': dto.name,
        'PhoneNumber': dto.phoneNumber,
        'Password': dto.password,
        'ConfirmPassword': dto.confirmPassword,
        'ChurchId': dto.churchId.toString(),
        'MeetingId': dto.meetingId.toString(),
        if (dto.birthDate != null) 'BirthDate': dto.birthDate,
        if (dto.joiningDate != null) 'JoiningDate': dto.joiningDate,
        if (dto.image != null)
          'Image': await MultipartFile.fromFile(dto.image!.path,
              filename: dto.image!.path.split('/').last),
        if (dto.classroomsIds != null)
          for (var i = 0; i < dto.classroomsIds!.length; i++)
            'classroomsIds[$i]': dto.classroomsIds![i].toString(),
      };
      final response = await _dio.post(
        AppConstants.registerServantEndpoint,
        data: FormData.fromMap(map),
      );
      final token =
          (response.data as Map<String, dynamic>)['token'] as String;
      await TokenStorage.saveToken(token);
      return token;
    });
  }

  /// Church super-admin registration:
  /// POST /api/Account/register-church-superadmin
  /// Multipart/form-data — response body: { "token": "<jwt>" }
  Future<String> registerChurchSuperAdmin(
      RegisterChurchSuperAdminDto dto) async {
    return apiCall(() async {
      final map = <String, dynamic>{
        'Name': dto.name,
        'PhoneNumber': dto.phoneNumber,
        'Password': dto.password,
        'ConfirmPassword': dto.confirmPassword,
        'ChurchName': dto.churchName,
        if (dto.birthDate != null) 'BirthDate': dto.birthDate,
        if (dto.joiningDate != null) 'JoiningDate': dto.joiningDate,
        if (dto.image != null)
          'Image': await MultipartFile.fromFile(dto.image!.path,
              filename: dto.image!.path.split('/').last),
      };
      final response = await _dio.post(
        AppConstants.registerChurchSuperAdminEndpoint,
        data: FormData.fromMap(map),
      );
      final token =
          (response.data as Map<String, dynamic>)['token'] as String;
      await TokenStorage.saveToken(token);
      return token;
    });
  }

  /// Meeting-admin registration:
  /// POST /api/Account/register-meeting-admin-new-church
  /// Multipart/form-data — response body: { "token": "<jwt>" }
  Future<String> registerMeetingAdmin(RegisterMeetingAdminDto dto) async {
    return apiCall(() async {
      final map = <String, dynamic>{
        'Name': dto.name,
        'PhoneNumber': dto.phoneNumber,
        'Password': dto.password,
        'ConfirmPassword': dto.confirmPassword,
        'ChurchName': dto.churchName,
        'MeetingName': dto.meetingName,
        'Weekly_appointment': dto.weeklyAppointment.toIso8601String(),
        if (dto.birthDate != null) 'BirthDate': dto.birthDate,
        if (dto.joiningDate != null) 'JoiningDate': dto.joiningDate,
        if (dto.image != null)
          'Image': await MultipartFile.fromFile(dto.image!.path,
              filename: dto.image!.path.split('/').last),
      };
      final response = await _dio.post(
        AppConstants.registerMeetingAdminEndpoint,
        data: FormData.fromMap(map),
      );
      final token =
          (response.data as Map<String, dynamic>)['token'] as String;
      await TokenStorage.saveToken(token);
      return token;
    });
  }

  Future<void> logout() async {
    await TokenStorage.deleteToken();
  }
}
