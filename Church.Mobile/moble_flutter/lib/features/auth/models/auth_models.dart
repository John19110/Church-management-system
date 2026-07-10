import 'dart:io';
import 'package:flutter/material.dart';

/// Result from login/register — JWT or phone verification required.
class AuthFlowResult {
  final String? token;
  final bool requiresPhoneVerification;
  final String? phoneNumber;
  final String? message;

  const AuthFlowResult({
    this.token,
    this.requiresPhoneVerification = false,
    this.phoneNumber,
    this.message,
  });

  bool get hasToken => token != null && token!.isNotEmpty;
}

class PhoneOtpDto {
  final String phoneNumber;
  const PhoneOtpDto({required this.phoneNumber});
  Map<String, dynamic> toJson() => {'phoneNumber': phoneNumber};
}

class VerifyOtpDto {
  final String phoneNumber;
  final String code;
  const VerifyOtpDto({required this.phoneNumber, required this.code});
  Map<String, dynamic> toJson() => {'phoneNumber': phoneNumber, 'code': code};
}

class ResetPasswordDto {
  final String phoneNumber;
  final String code;
  final String newPassword;
  const ResetPasswordDto({
    required this.phoneNumber,
    required this.code,
    required this.newPassword,
  });
  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'code': code,
        'newPassword': newPassword,
      };
}

class LoginDto {
  final String phoneNumber;
  final String password;

  const LoginDto({required this.phoneNumber, required this.password});

  Map<String, dynamic> toJson() =>
      {'phoneNumber': phoneNumber, 'password': password};
}

/// Used for servant self-registration via /api/Account/register-servant
class RegisterServantDto {
  final String name;
  final String phoneNumber;
  final String password;
  final String confirmPassword;
  final String churchPublicId;

  /// Free-text meeting name the user wants to join (assigned by Super Admin on approval).
  final String requestedMeetingName;

  /// Requested role: 'Servant' | 'MeetingAdmin' | 'ChurchAdmin'.
  final String requestedRole;

  /// Phone of the Meeting Admin responsible for the requested meeting (servants only).
  final String? meetingAdminPhoneNumber;

  /// Legacy public meeting id — optional, no longer required for self-registration.
  final String meetingPublicId;
  final File? image;
  final String? birthDate;
  final String? joiningDate;
  final List<int>? classroomsIds;

  const RegisterServantDto({
    required this.name,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
    required this.churchPublicId,
    required this.requestedMeetingName,
    this.requestedRole = 'Servant',
    this.meetingAdminPhoneNumber,
    this.meetingPublicId = '',
    this.image,
    this.birthDate,
    this.joiningDate,
    this.classroomsIds,
  });
}

/// Used for church super-admin registration via
/// /api/Account/register-church-superadmin
class RegisterChurchSuperAdminDto {
  final String name;
  final String phoneNumber;
  final String password;
  final String confirmPassword;
  final String churchName;
  final File? image;
  final String? birthDate;
  final String? joiningDate;

  const RegisterChurchSuperAdminDto({
    required this.name,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
    required this.churchName,
    this.image,
    this.birthDate,
    this.joiningDate,
  });
}

/// Used for meeting-admin registration via
/// /api/Account/register-meeting-admin-new-church
class RegisterMeetingAdminDto {
  final String name;
  final String phoneNumber;
  final String password;
  final String confirmPassword;
  final String churchName;
  final String meetingName;
  final TimeOfDay weeklyAppointment;
  final String dayOfWeek;
  final File? image;
  final String? birthDate;
  final String? joiningDate;

  const RegisterMeetingAdminDto({
    required this.name,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
    required this.churchName,
    required this.meetingName,
    required this.weeklyAppointment,
    required this.dayOfWeek,
    this.image,
    this.birthDate,
    this.joiningDate,
  });
}
