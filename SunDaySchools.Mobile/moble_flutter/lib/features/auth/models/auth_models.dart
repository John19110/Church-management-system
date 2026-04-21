import 'dart:io';
import 'package:flutter/material.dart';

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
  final int churchId;
  final int meetingId;
  final File? image;
  final String? birthDate;
  final String? joiningDate;
  final List<int>? classroomsIds;

  const RegisterServantDto({
    required this.name,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
    required this.churchId,
    required this.meetingId,
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
