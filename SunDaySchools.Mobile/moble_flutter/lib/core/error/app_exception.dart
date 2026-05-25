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
  const UnauthorizedException()
      : super('Your session has expired. Please sign in again.', statusCode: 401);
}

class NetworkException extends AppException {
  const NetworkException()
      : super('Network error. Please check your connection and try again.');
}

/// User-facing text for any error thrown from repositories or UI catch blocks.
String userFriendlyMessage(Object error) {
  if (error is AppException) return error.message;
  if (error is DioException) return mapDioException(error).message;
  final text = error.toString();
  if (_looksLikeTechnicalError(text)) {
    return 'Something went wrong. Please try again.';
  }
  return text;
}

bool _looksLikeTechnicalError(String text) {
  final lower = text.toLowerCase();
  return lower.contains('exception') ||
      lower.contains('stacktrace') ||
      lower.contains('sqlexception') ||
      lower.contains(' at ') ||
      text.length > 200;
}

String? _messageFromResponseData(dynamic data) {
  if (data is Map<String, dynamic>) {
    final message = data['message'];
    if (message != null) return message.toString();
  }
  if (data is String && data.trim().isNotEmpty && !_looksLikeTechnicalError(data)) {
    return data.trim();
  }
  return null;
}

/// Maps a [DioException] to a user-friendly [AppException].
AppException mapDioException(DioException e) {
  if (e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return const NetworkException();
  }

  final statusCode = e.response?.statusCode;
  if (statusCode == 401) return const UnauthorizedException();

  final data = e.response?.data;
  if (data is Map<String, dynamic>) {
    if (data['errorCode'] == 'PHONE_NOT_VERIFIED' &&
        data['requiresPhoneVerification'] == true) {
      return ApiException(
        data['message']?.toString() ?? 'Phone verification required.',
        statusCode: 403,
      );
    }
    if (data['errorCode'] == 'OTP_RATE_LIMIT') {
      return ApiException(
        data['message']?.toString() ??
            'Too many attempts. Please wait before trying again.',
        statusCode: 429,
      );
    }
    final apiMessage = _messageFromResponseData(data);
    if (apiMessage != null) {
      return ApiException(apiMessage, statusCode: statusCode);
    }
  }

  if (statusCode != null && statusCode >= 500) {
    return ApiException(
      'Server error. Please try again later.',
      statusCode: statusCode,
    );
  }

  final fallback = _messageFromResponseData(data);
  if (fallback != null) {
    return ApiException(fallback, statusCode: statusCode);
  }

  return ApiException(
    e.message ?? 'An error occurred. Please try again.',
    statusCode: statusCode,
  );
}
