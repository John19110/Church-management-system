import 'dart:io';

class AppConstants {
  // When using USB + adb reverse the phone should call localhost
  static String baseUrl = Platform.isAndroid
      ? 'http://127.0.0.1:5000'
      : 'http://localhost:5000';

  // Auth endpoints
  static const String loginEndpoint = '/api/Account/login';
  static const String registerServantEndpoint = '/api/Account/register-servant';
  static const String registerChurchSuperAdminEndpoint =
      '/api/Account/register-church-superadmin';
  static const String registerMeetingAdminEndpoint =
      '/api/Account/register-meeting-admin-new-church';

  // Members (children) endpoints
  static const String membersEndpoint = '/api/Member';
  // POST /api/classrooms/{classroomId}/members
  static const String classroomMembersBasePath = '/api/classroom';

  // Servant endpoints
  static const String servantEndpoint = '/api/Servant';

  // Admin endpoints
  static const String adminEndpoint = '/Api/Admin';

  // Classroom endpoints
  static const String classroomEndpoint = '/api/Classroom';

  // Meeting endpoints
  static const String meetingEndpoint = '/api/Meeting';

  // SuperAdmin endpoints
  static const String superAdminEndpoint = '/api/SuperAdmin';

  // AttendanceSession endpoints
  static const String attendanceEndpoint = '/api/AttendanceSession';

  static const String tokenKey = 'jwt_token';
}