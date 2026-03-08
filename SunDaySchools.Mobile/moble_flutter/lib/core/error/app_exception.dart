import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiException extends AppException {
  const ApiException(super.message, {super.statusCode});
}

class UnauthorizedException extends AppException {
  const UnauthorizedException() : super('Unauthorized. Please log in again.', statusCode: 401);
}

class NetworkException extends AppException {
  const NetworkException() : super('Network error. Please check your connection.');
}

/// Maps a [DioException] to a user-friendly [AppException].
AppException mapDioException(DioException e) {
  if (e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return const NetworkException();
  }
  final statusCode = e.response?.statusCode;
  if (statusCode == 401) return const UnauthorizedException();
  final message = e.response?.data?.toString() ?? e.message ?? 'An error occurred';
  return ApiException(message, statusCode: statusCode);
}
