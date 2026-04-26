class AppConstants {
  /// Base URL for the deployed ASP.NET API (HTTPS FIXED)
  static const String baseUrl = 'https://mychurch.runasp.net';

  // Auth endpoints
  static const String loginEndpoint = '/api/Account/login';
  static const String logoutEndpoint = '/api/Account/logout';
  static const String registerServantEndpoint = '/api/Account/register-servant';
  static const String registerChurchSuperAdminEndpoint =
      '/api/Account/register-church-superadmin';
  static const String registerMeetingAdminEndpoint =
      '/api/Account/register-meeting-admin-new-church';

  // Members (children) endpoints
  static const String membersEndpoint = '/api/Member';
  static const String classroomMembersBasePath = '/api/classrooms';

  // Servant endpoints
  static const String servantEndpoint = '/api/Servant';
  static const String servantProfileEndpoint = '/api/Servant/profile';

  // Admin endpoints
  static const String adminEndpoint = '/api/Admin';

  // Classroom endpoints
  static const String classroomEndpoint = '/api/Classroom';

  // Meeting endpoints
  static const String meetingEndpoint = '/api/Meeting';

  // SuperAdmin endpoints
  static const String superAdminEndpoint = '/api/SuperAdmin';

  // AttendanceSession endpoints
  static const String attendanceEndpoint = '/api/AttendanceSession';
  static const String attendanceByClassroomEndpoint =
      '/api/AttendanceSession/by-classroom';

  // Select endpoints (all return: {id, name})
  static const String classroomsSelectEndpoint = '/api/Classroom/select';
  static const String membersSelectEndpoint = '/api/Member/select';
  static const String meetingsSelectEndpoint = '/api/Meeting/select';
  static const String servantsSelectEndpoint = '/api/Servant/select';

  static const String tokenKey = 'jwt_token';
}