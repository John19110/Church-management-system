import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

const String _defaultApiErrorMessage = 'An error occurred. Please try again.';

class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiException extends AppException {
  final String? errorCode;
  final bool requiresPhoneVerification;
  final String? phoneNumber;
  final int? retryAfterSeconds;

  const ApiException(
    super.message, {
    super.statusCode,
    this.errorCode,
    this.requiresPhoneVerification = false,
    this.phoneNumber,
    this.retryAfterSeconds,
  });
}

class UnauthorizedException extends AppException {
  const UnauthorizedException()
      : super('Your session has expired. Please sign in again.', statusCode: 401);
}

class NetworkException extends AppException {
  const NetworkException()
      : super('Network error. Please check your connection and try again.');
}

/// Normalized API error parsed from legacy or RFC 7807 ProblemDetails bodies.
class ParsedApiError {
  final String? errorCode;
  final String message;
  final int? status;
  final bool requiresPhoneVerification;
  final String? phoneNumber;
  final int? retryAfterSeconds;

  const ParsedApiError({
    required this.message,
    this.errorCode,
    this.status,
    this.requiresPhoneVerification = false,
    this.phoneNumber,
    this.retryAfterSeconds,
  });
}

/// Parses legacy `{ success, errorCode, message }` and RFC 7807 ProblemDetails.
ParsedApiError parseApiError(
  dynamic responseBody, {
  int? httpStatusCode,
  String defaultMessage = _defaultApiErrorMessage,
}) {
  final map = _asJsonMap(responseBody);
  if (map == null) {
    final text = _plainTextMessage(responseBody);
    return ParsedApiError(
      message: text ?? defaultMessage,
      status: httpStatusCode,
    );
  }

  final errorCode = _errorCodeFromMap(map);
  final status = httpStatusCode ?? _statusFromMap(map);
  final message = _primaryMessage(map) ?? defaultMessage;

  if (_isPhoneNotVerified(map, errorCode)) {
    return ParsedApiError(
      errorCode: 'PHONE_NOT_VERIFIED',
      message: message,
      status: status ?? 403,
      requiresPhoneVerification: true,
      phoneNumber: map['phoneNumber']?.toString(),
    );
  }

  if (_isOtpRateLimit(map, errorCode)) {
    return ParsedApiError(
      errorCode: 'OTP_RATE_LIMIT',
      message: message,
      status: status ?? 429,
      retryAfterSeconds: _retryAfterSecondsFromMap(map),
    );
  }

  return ParsedApiError(
    errorCode: errorCode,
    message: message,
    status: status,
  );
}

/// User-facing text for any error thrown from repositories or UI catch blocks.
String userFriendlyMessage(Object error, [AppLocalizations? l10n]) {
  final loc = l10n ?? AppLocalizations.forLocale(const Locale('en'));

  if (error is UnauthorizedException) return loc.sessionExpiredPleaseSignIn;
  if (error is NetworkException) return loc.networkErrorTryAgain;
  if (error is AppException && error.message.isNotEmpty) return error.message;
  if (error is DioException) {
    return userFriendlyMessage(mapDioException(error), loc);
  }

  final text = error.toString();
  if (_looksLikeTechnicalError(text)) {
    return loc.somethingWentWrongTryAgain;
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

Map<String, dynamic>? _asJsonMap(dynamic body) {
  if (body is Map<String, dynamic>) return body;
  if (body is Map) {
    try {
      return Map<String, dynamic>.from(body);
    } catch (_) {
      return null;
    }
  }
  return null;
}

String? _plainTextMessage(dynamic body) {
  if (body is String) {
    final trimmed = body.trim();
    if (trimmed.isNotEmpty && !_looksLikeTechnicalError(trimmed)) {
      return trimmed;
    }
  }
  return null;
}

String? _errorCodeFromMap(Map<String, dynamic> map) {
  final raw = map['errorCode'] ?? map['type'];
  if (raw == null) return null;
  final code = raw.toString().trim();
  return code.isEmpty ? null : code;
}

int? _statusFromMap(Map<String, dynamic> map) {
  final raw = map['status'];
  if (raw is int) return raw;
  if (raw == null) return null;
  return int.tryParse(raw.toString());
}

int? _retryAfterSecondsFromMap(Map<String, dynamic> map) {
  final raw = map['retryAfterSeconds'];
  if (raw is int) return raw;
  if (raw == null) return null;
  return int.tryParse(raw.toString());
}

/// Priority: title (ProblemDetails) → message (legacy) → detail (ProblemDetails).
String? _primaryMessage(Map<String, dynamic> map) {
  for (final key in const ['title', 'message', 'detail']) {
    final value = map[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}

bool _isPhoneNotVerified(Map<String, dynamic> map, String? errorCode) {
  if (errorCode == 'PHONE_NOT_VERIFIED') return true;
  return map['requiresPhoneVerification'] == true &&
      (map['errorCode'] == 'PHONE_NOT_VERIFIED' || map['type'] == 'PHONE_NOT_VERIFIED');
}

bool _isOtpRateLimit(Map<String, dynamic> map, String? errorCode) {
  if (errorCode == 'OTP_RATE_LIMIT') return true;
  return map['errorCode'] == 'OTP_RATE_LIMIT' || map['type'] == 'OTP_RATE_LIMIT';
}

ApiException _apiExceptionFromParsed(ParsedApiError parsed) {
  return ApiException(
    parsed.message,
    statusCode: parsed.status,
    errorCode: parsed.errorCode,
    requiresPhoneVerification: parsed.requiresPhoneVerification,
    phoneNumber: parsed.phoneNumber,
    retryAfterSeconds: parsed.retryAfterSeconds,
  );
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

  final parsed = parseApiError(
    e.response?.data,
    httpStatusCode: statusCode,
  );

  if (parsed.requiresPhoneVerification || parsed.errorCode == 'OTP_RATE_LIMIT') {
    return _apiExceptionFromParsed(parsed);
  }

  if (parsed.message != _defaultApiErrorMessage ||
      parsed.errorCode != null ||
      parsed.status != null) {
    return _apiExceptionFromParsed(parsed);
  }

  if (statusCode != null && statusCode >= 500) {
    return ApiException(
      AppLocalizations.forLocale(const Locale('en')).serverErrorTryLater,
      statusCode: statusCode,
      errorCode: parsed.errorCode ?? 'SERVER_ERROR',
    );
  }

  return ApiException(
    e.message ?? AppLocalizations.forLocale(const Locale('en')).genericErrorTryAgain,
    statusCode: statusCode,
    errorCode: parsed.errorCode,
  );
}
