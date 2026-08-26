class AppConstants {
  /// Production ASP.NET Core API on Azure App Service (HTTPS).
  static const String productionBaseUrl =
      'https://mychurch-czdwf2enfdfrhchd.uaenorth-01.azurewebsites.net';

  /// Optional local backends (pass via --dart-define=API_BASE_URL=...).
  /// Android emulator: http://10.0.2.2:5000
  /// iOS simulator:    http://127.0.0.1:5000
  /// Physical device:  http://<lan-ip>:5000
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:5000';
  static const String iosSimulatorBaseUrl = 'http://127.0.0.1:5000';

  /// Active API host. Defaults to [productionBaseUrl].
  ///
  /// Override without editing source, e.g.:
  /// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: productionBaseUrl,
  );

  // Auth endpoints
  static const String loginEndpoint = '/api/Account/login';
  static const String logoutEndpoint = '/api/Account/logout';
  static const String deleteAccountEndpoint = '/api/Account';
  static const String registerServantEndpoint = '/api/Account/register-servant';
  static const String registerChurchSuperAdminEndpoint =
      '/api/Account/register-church-superadmin';
  static const String registerMeetingAdminEndpoint =
      '/api/Account/register-meeting-admin-new-church';

  /// FCM device-token registration with the ASP.NET API.
  /// Empty until the backend ships the endpoint — see [FcmTokenRegistrar].
  /// Planned: `PUT /api/DeviceToken` (authenticated).
  static const String deviceTokenEndpoint = '';

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

  // Church endpoints
  static const String churchEndpoint = '/api/Church';

  // SuperAdmin endpoints
  static const String superAdminEndpoint = '/api/SuperAdmin';

  // Custom fields
  static const String customFieldEndpoint = '/api/CustomField';

  // AttendanceSession endpoints
  static const String attendanceEndpoint = '/api/AttendanceSession';
  static const String attendanceByClassroomEndpoint =
      '/api/AttendanceSession/by-classroom';
  static const String attendanceByMeetingEndpoint =
      '/api/AttendanceSession/by-meeting';

  static String meetingAttendanceCriteriaEndpoint(int meetingId) =>
      '/api/Meeting/$meetingId/attendance-criteria';
  static String attendanceCriterionEndpoint(int id) =>
      '/api/attendance-criteria/$id';
  static String meetingAttendanceCriteriaReorderEndpoint(int meetingId) =>
      '/api/Meeting/$meetingId/attendance-criteria/reorder';

  // Select endpoints (all return: {id, name})
  static const String classroomsSelectEndpoint = '/api/Classroom/select';
  static const String meetingsSelectEndpoint = '/api/Meeting/select';
  static const String membersSelectEndpoint = '/api/Member/select';
  static const String servantsSelectEndpoint = '/api/Servant/select';

  static const String tokenKey = 'jwt_token';

  // Meeting-scoped endpoints
  static String meetingMembersEndpoint(int meetingId) =>
      '/api/Meeting/$meetingId/members';
  static String meetingMembersCreateEndpoint(int meetingId) =>
      '/api/meetings/$meetingId/members';
  static String meetingServantsEndpoint(int meetingId) =>
      '/api/Meeting/$meetingId/servants';
}
