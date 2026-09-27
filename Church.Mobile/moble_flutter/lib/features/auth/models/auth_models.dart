import 'package:flutter/material.dart';

import '../../../core/media/picked_image.dart';

/// Result from login/register — JWT on success, or a registration message.
class AuthFlowResult {
  final String? token;
  final String? message;

  const AuthFlowResult({
    this.token,
    this.message,
  });

  bool get hasToken => token != null && token!.isNotEmpty;
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
  final PickedImage? image;
  final String? birthDate;
  final String? joiningDate;
  final List<int>? classroomsIds;
  final String? preferredLanguage;

  const RegisterServantDto({
    required this.name,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
    required this.churchPublicId,
    this.requestedMeetingName = '',
    this.requestedRole = 'Servant',
    this.meetingAdminPhoneNumber,
    this.meetingPublicId = '',
    this.image,
    this.birthDate,
    this.joiningDate,
    this.classroomsIds,
    this.preferredLanguage,
  });
}

class RegisterChurchSuperAdminDto {
  final String name;
  final String phoneNumber;
  final String password;
  final String confirmPassword;
  final String churchName;
  final PickedImage? image;
  final String? birthDate;
  final String? joiningDate;
  final String? supportedLanguages;
  final String? defaultLanguage;
  final String? preferredLanguage;

  const RegisterChurchSuperAdminDto({
    required this.name,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
    required this.churchName,
    this.image,
    this.birthDate,
    this.joiningDate,
    this.supportedLanguages,
    this.defaultLanguage,
    this.preferredLanguage,
  });
}

class RegisterMeetingAdminDto {
  final String name;
  final String phoneNumber;
  final String password;
  final String confirmPassword;
  final String churchName;
  final String meetingName;
  final TimeOfDay weeklyAppointment;
  final String dayOfWeek;
  final bool hasClassrooms;
  final PickedImage? image;
  final String? birthDate;
  final String? joiningDate;
  final String? supportedLanguages;
  final String? defaultLanguage;
  final String? preferredLanguage;

  const RegisterMeetingAdminDto({
    required this.name,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
    required this.churchName,
    required this.meetingName,
    required this.weeklyAppointment,
    required this.dayOfWeek,
    this.hasClassrooms = true,
    this.image,
    this.birthDate,
    this.joiningDate,
    this.supportedLanguages,
    this.defaultLanguage,
    this.preferredLanguage,
  });
}
