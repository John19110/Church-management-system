class AppConstants {
  // Change this to your backend server address
  static const String baseUrl = 'http://10.0.2.2:5000';

  // Auth endpoints (capital A)
  static const String loginEndpoint = '/Api/Account/Login';
  static const String registerEndpoint = '/Api/Account/Register';

  // Children endpoints (lowercase a, capital C)
  static const String childrenEndpoint = '/api/Children';

  // Servant endpoints (lowercase a, lowercase s)
  static const String servantEndpoint = '/api/servant';

  // AttendanceSession endpoints (lowercase a, capital A, capital S)
  static const String attendanceEndpoint = '/api/AttendanceSession';

  static const String tokenKey = 'jwt_token';
}
