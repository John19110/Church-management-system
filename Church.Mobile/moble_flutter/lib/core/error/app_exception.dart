import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/validation_message_localizer.dart';

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
  /// Field name → list of messages from API validation (`errors` map).
  final Map<String, List<String>> fieldErrors;

  const ApiException(
    super.message, {
    super.statusCode,
    this.errorCode,
    this.fieldErrors = const {},
  });

  bool get hasFieldErrors => fieldErrors.isNotEmpty;
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
  final Map<String, List<String>> fieldErrors;

  const ParsedApiError({
    required this.message,
    this.errorCode,
    this.status,
    this.fieldErrors = const {},
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
  final fieldErrors = _fieldErrorsFromMap(map);
  final message = _primaryMessage(map, fieldErrors) ?? defaultMessage;

  return ParsedApiError(
    errorCode: errorCode,
    message: message,
    status: status,
    fieldErrors: fieldErrors,
  );
}

/// User-facing text for any error thrown from repositories or UI catch blocks.
String userFriendlyMessage(Object error, [AppLocalizations? l10n]) {
  final loc = l10n ?? AppLocalizations.forLocale(const Locale('en'));

  if (error is ApiException && error.errorCode == 'AUTH_FAILED') {
    return loc.invalidCredentialsPleaseTryAgain;
  }
  if (error is ApiException &&
      (error.errorCode == 'VALIDATION_ERROR' ||
          error.errorCode == 'MODEL_BINDING_ERROR')) {
    if (error.hasFieldErrors) {
      final localized = ValidationMessageLocalizer.localizeFieldErrors(
        loc,
        error.fieldErrors,
      );
      final joined = localized.values.expand((m) => m).join('\n');
      if (joined.isNotEmpty) return joined;
    }
    return ValidationMessageLocalizer.localize(loc, error.message);
  }
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

bool _isGenericValidationTitle(String text) {
  final lower = text.trim().toLowerCase();
  return lower == 'validation error' ||
      lower == 'validation failed' ||
      lower == 'one or more validation errors occurred.' ||
      lower == 'one or more fields failed model binding or validation.';
}

/// Prefer concrete detail / field messages over generic ProblemDetails titles.
String? _primaryMessage(
  Map<String, dynamic> map,
  Map<String, List<String>> fieldErrors,
) {
  final title = _stringField(map, 'title');
  final message = _stringField(map, 'message');
  final detail = _stringField(map, 'detail');
  final joinedErrors = fieldErrors.values
      .expand((messages) => messages)
      .map((m) => m.trim())
      .where((m) => m.isNotEmpty)
      .toList();

  if (message != null && !_isGenericValidationTitle(message)) return message;
  if (detail != null && !_isGenericValidationTitle(detail)) return detail;
  if (joinedErrors.isNotEmpty) return joinedErrors.join('\n');
  if (message != null) return message;
  if (detail != null) return detail;
  if (title != null && !_isGenericValidationTitle(title)) return title;
  if (title != null) return title;
  return null;
}

String? _stringField(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

Map<String, List<String>> _fieldErrorsFromMap(Map<String, dynamic> map) {
  final raw = map['errors'];
  if (raw is! Map) return const {};

  final result = <String, List<String>>{};
  raw.forEach((key, value) {
    final field = key.toString().trim();
    if (field.isEmpty) return;

    final messages = <String>[];
    if (value is List) {
      for (final item in value) {
        final text = item?.toString().trim() ?? '';
        if (text.isNotEmpty) messages.add(text);
      }
    } else if (value != null) {
      final text = value.toString().trim();
      if (text.isNotEmpty) messages.add(text);
    }

    if (messages.isNotEmpty) {
      result[field] = messages;
    }
  });
  return result;
}

ApiException _apiExceptionFromParsed(ParsedApiError parsed) {
  return ApiException(
    parsed.message,
    statusCode: parsed.status,
    errorCode: parsed.errorCode,
    fieldErrors: parsed.fieldErrors,
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
  final parsed = parseApiError(
    e.response?.data,
    httpStatusCode: statusCode,
  );

  // Login invalid credentials: 401 + AUTH_FAILED (not an expired session).
  if (statusCode == 401) {
    if (parsed.errorCode == 'AUTH_FAILED') {
      return ApiException(
        parsed.message,
        statusCode: 401,
        errorCode: 'AUTH_FAILED',
        fieldErrors: parsed.fieldErrors,
      );
    }
    return const UnauthorizedException();
  }

  if (parsed.message != _defaultApiErrorMessage ||
      parsed.errorCode != null ||
      parsed.status != null ||
      parsed.fieldErrors.isNotEmpty) {
    return _apiExceptionFromParsed(parsed);
  }

  if (statusCode != null && statusCode >= 500) {
    return ApiException(
      AppLocalizations.forLocale(const Locale('en')).serverErrorTryLater,
      statusCode: statusCode,
      errorCode: parsed.errorCode ?? 'SERVER_ERROR',
      fieldErrors: parsed.fieldErrors,
    );
  }

  return ApiException(
    e.message ?? AppLocalizations.forLocale(const Locale('en')).genericErrorTryAgain,
    statusCode: statusCode,
    errorCode: parsed.errorCode,
    fieldErrors: parsed.fieldErrors,
  );
}
