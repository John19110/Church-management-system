import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/storage/token_storage.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  static String _formatTimeOfDay(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm:00';
  }

  AuthFlowResult _parseAuthResponse(Map<String, dynamic> data) {
    final token = data['token'] as String?;
    return AuthFlowResult(token: token);
  }

  Future<AuthFlowResult> login(LoginDto dto) async {
    return apiCall(() async {
      final response = await _dio.post(
        AppConstants.loginEndpoint,
        data: dto.toJson(),
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final result = _parseAuthResponse(data);
      if (result.hasToken) {
        await TokenStorage.saveToken(result.token!);
      }
      return result;
    });
  }

  Future<AuthFlowResult> registerServant(RegisterServantDto dto) async {
    return apiCall(() async {
      final map = <String, dynamic>{
        'Name': dto.name,
        'PhoneNumber': dto.phoneNumber,
        'Password': dto.password,
        'ConfirmPassword': dto.confirmPassword,
        'ChurchPublicId': dto.churchPublicId,
        'RequestedMeetingName': dto.requestedMeetingName,
        'RequestedRole': dto.requestedRole,
        if (dto.meetingAdminPhoneNumber != null &&
            dto.meetingAdminPhoneNumber!.isNotEmpty)
          'MeetingAdminPhoneNumber': dto.meetingAdminPhoneNumber,
        if (dto.meetingPublicId.isNotEmpty)
          'MeetingPublicId': dto.meetingPublicId,
        if (dto.birthDate != null) 'BirthDate': dto.birthDate,
        if (dto.joiningDate != null) 'JoiningDate': dto.joiningDate,
        if (dto.image != null)
          'Image': await MultipartFile.fromFile(
            dto.image!.path,
            filename: dto.image!.path.split('/').last,
          ),
        if (dto.classroomsIds != null)
          for (var i = 0; i < dto.classroomsIds!.length; i++)
            'classroomsIds[$i]': dto.classroomsIds![i].toString(),
      };
      final response = await _dio.post(
        AppConstants.registerServantEndpoint,
        data: FormData.fromMap(map),
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final result = _parseAuthResponse(data);
      if (result.hasToken) {
        await TokenStorage.saveToken(result.token!);
      }
      return result;
    });
  }

  Future<AuthFlowResult> registerChurchSuperAdmin(
    RegisterChurchSuperAdminDto dto,
  ) async {
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
          'Image': await MultipartFile.fromFile(
            dto.image!.path,
            filename: dto.image!.path.split('/').last,
          ),
      };
      final response = await _dio.post(
        AppConstants.registerChurchSuperAdminEndpoint,
        data: FormData.fromMap(map),
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final result = _parseAuthResponse(data);
      if (result.hasToken) {
        await TokenStorage.saveToken(result.token!);
      }
      return result;
    });
  }

  Future<AuthFlowResult> registerMeetingAdmin(
    RegisterMeetingAdminDto dto,
  ) async {
    return apiCall(() async {
      final map = <String, dynamic>{
        'Name': dto.name,
        'PhoneNumber': dto.phoneNumber,
        'Password': dto.password,
        'ConfirmPassword': dto.confirmPassword,
        'ChurchName': dto.churchName,
        'MeetingName': dto.meetingName,
        'Weekly_appointment': _formatTimeOfDay(dto.weeklyAppointment),
        'DayOfWeek': dto.dayOfWeek,
        'dayOfWeek': dto.dayOfWeek,
        if (dto.birthDate != null) 'BirthDate': dto.birthDate,
        if (dto.joiningDate != null) 'JoiningDate': dto.joiningDate,
        if (dto.image != null)
          'Image': await MultipartFile.fromFile(
            dto.image!.path,
            filename: dto.image!.path.split('/').last,
          ),
      };
      final response = await _dio.post(
        AppConstants.registerMeetingAdminEndpoint,
        data: FormData.fromMap(map),
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final result = _parseAuthResponse(data);
      if (result.hasToken) {
        await TokenStorage.saveToken(result.token!);
      }
      return result;
    });
  }

  Future<void> logout() async {
    try {
      await _dio.post(AppConstants.logoutEndpoint);
    } on DioException {
      // Still clear local session
    } finally {
      await TokenStorage.deleteToken();
    }
  }

  /// Permanently deletes the authenticated account on the server.
  Future<void> deleteAccount() async {
    await apiCall(() async {
      await _dio.delete<void>(AppConstants.deleteAccountEndpoint);
    });
  }
}
