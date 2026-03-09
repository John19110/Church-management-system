import 'dart:io';

class AppConstants {
  // When using USB + adb reverse the phone should call localhost
  static String baseUrl = Platform.isAndroid
      ? 'http://127.0.0.1:5000'
      : 'http://localhost:5000';

  // Auth endpoints
  static const String loginEndpoint = '/Api/Account/Login';
  static const String registerEndpoint = '/Api/Account/Register';

  // Children endpoints
  static const String childrenEndpoint = '/api/Children';

  // Servant endpoints
  static const String servantEndpoint = '/api/servant';

  // AttendanceSession endpoints
  static const String attendanceEndpoint = '/api/AttendanceSession';

  static const String tokenKey = 'jwt_token';
}