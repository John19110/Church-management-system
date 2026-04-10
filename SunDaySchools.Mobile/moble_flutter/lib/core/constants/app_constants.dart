import 'dart:io';

class AppConstants {
  /// Base URL for the ASP.NET API (no trailing slash).
  ///
  /// - **Android emulator (AVD):** `10.0.2.2` is the host machine’s loopback.
  /// - **Android physical device:** use your PC’s LAN IP, or run
  ///   `adb reverse tcp:5000 tcp:5000` and set host to `127.0.0.1`.
  /// - **iOS Simulator:** `localhost` is the Mac host.
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
  // POST /api/classrooms/{classroomId}/members (matches MemberController absolute route)
  static const String classroomMembersBasePath = '/api/classrooms';

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