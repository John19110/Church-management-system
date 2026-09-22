class AppConstants {
  /// Production ASP.NET Core API on Azure App Service (HTTPS).
  static const String productionBaseUrl =
      'https://mychurchwebapp-cdfpdedgfdd7cqhb.germanywestcentral-01.azurewebsites.net';

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

  // Auth endpoints (domain actions — intentional verbs)
  static const String loginEndpoint = '/api/account/login';
  static const String logoutEndpoint = '/api/account/logout';
  static const String deleteAccountEndpoint = '/api/account';
  static const String registerServantEndpoint = '/api/account/register-servant';
  static const String registerChurchSuperAdminEndpoint =
      '/api/account/register-church-superadmin';
  static const String registerMeetingAdminEndpoint =
      '/api/account/register-meeting-admin-new-church';

  /// Login/register must not send a leftover Bearer token.
  static bool isAnonymousAuthPath(String path) {
    final normalized = path.toLowerCase();
    return normalized.contains(loginEndpoint) ||
        normalized.contains('/api/account/register-');
  }

  /// FCM device-token registration with the ASP.NET API.
  /// Empty until the backend ships the endpoint — see [FcmTokenRegistrar].
  /// Planned: `PUT /api/device-tokens` (authenticated).
  static const String deviceTokenEndpoint = '';

  // Members (children) endpoints
  static const String membersEndpoint = '/api/members';
  static const String classroomMembersBasePath = '/api/classrooms';

  // Servant endpoints
  static const String servantEndpoint = '/api/servants';
  static const String servantProfileEndpoint = '/api/servants/profile';

  // Admin endpoints
  static const String adminEndpoint = '/api/admin';

  // Classroom endpoints
  static const String classroomEndpoint = '/api/classrooms';

  // Meeting endpoints
  static const String meetingEndpoint = '/api/meetings';

  // Church endpoints
  static const String churchEndpoint = '/api/churches';

  // SuperAdmin endpoints
  static const String superAdminEndpoint = '/api/super-admin';

  // Custom fields
  static const String customFieldEndpoint = '/api/custom-fields';

  // AttendanceSession endpoints
  static const String attendanceEndpoint = '/api/attendance-sessions';

  static String meetingAttendanceCriteriaEndpoint(int meetingId) =>
      '/api/meetings/$meetingId/attendance-criteria';
  static String attendanceCriterionEndpoint(int id) =>
      '/api/attendance-criteria/$id';
  static String meetingAttendanceCriteriaReorderEndpoint(int meetingId) =>
      '/api/meetings/$meetingId/attendance-criteria/reorder';

  // Select endpoints (all return: {id, name})
  static const String classroomsSelectEndpoint = '/api/classrooms/select';
  static const String meetingsSelectEndpoint = '/api/meetings/select';
  static const String membersSelectEndpoint = '/api/members/select';
  static const String servantsSelectEndpoint = '/api/servants/select';

  static const String tokenKey = 'jwt_token';

  // Meeting-scoped endpoints
  static String meetingMembersEndpoint(int meetingId) =>
      '/api/meetings/$meetingId/members';
  static String meetingAllMembersEndpoint(int meetingId) =>
      '/api/meetings/$meetingId/members/all';
  static String meetingAssignedMembersEndpoint(int meetingId) =>
      '/api/meetings/$meetingId/members/assigned';
  static String meetingMembersCreateEndpoint(int meetingId) =>
      '/api/meetings/$meetingId/members';
  static String meetingServantsEndpoint(int meetingId) =>
      '/api/meetings/$meetingId/servants';
}
