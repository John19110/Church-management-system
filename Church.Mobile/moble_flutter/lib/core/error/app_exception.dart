import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/validation_message_localizer.dart';

const String _defaultApiErrorMessage = 'An error occurred. Please try again.';

/// 403 codes that describe the caller's account state rather than a missing
/// permission. `GlobalExceptionMiddleware` emits these as the ProblemDetails `type`.
const Set<String> _accountStatusErrorCodes = {
  'ACCOUNT_PENDING',
  'ACCOUNT_REJECTED',
};

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
  const NetworkException([String? detail])
      : super(
          detail ??
              'Network error. Please check your connection and try again.',
        );
}

class ForbiddenException extends AppException {
  const ForbiddenException()
      : super(
          "You don't have permission to perform this action.",
          statusCode: 403,
        );
}

class ApiTimeoutException extends AppException {
  const ApiTimeoutException()
      : super('The server took too long to respond. Please try again.');
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
  // Prefer the localized copy over the server's English detail for these.
  if (error is ApiException && error.errorCode == 'ACCOUNT_PENDING') {
    return loc.accountPendingApproval;
  }
  if (error is ApiException && error.errorCode == 'ACCOUNT_REJECTED') {
    return loc.accountRejected;
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
  if (error is ForbiddenException) {
    return error.message;
  }
  if (error is ApiTimeoutException) return error.message;
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
  if (kDebugMode) {
    debugPrint(
      'API ERROR type=${e.type} message=${e.message} '
      'url=${e.requestOptions.uri}',
    );
    debugPrint(
      'API ERROR status=${e.response?.statusCode} data=${e.response?.data}',
    );
    if (kIsWeb &&
        (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.unknown)) {
      debugPrint(
        'API ERROR hint: browser may have blocked this cross-origin request '
        '(check CORS / OPTIONS preflight in DevTools Network tab).',
      );
    }
  }

  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return const ApiTimeoutException();
  }

  if (e.type == DioExceptionType.connectionError ||
      (e.type == DioExceptionType.unknown && e.response == null)) {
    return const NetworkException();
  }

  final statusCode = e.response?.statusCode;
  final parsed = parseApiError(
    e.response?.data,
    httpStatusCode: statusCode,
  );

  // A 403 is either "your account is not usable yet" or a genuine permission denial.
  // The API tells them apart with a structured code, so keep the code instead of
  // collapsing every 403 into the permission message.
  if (statusCode == 403) {
    if (_accountStatusErrorCodes.contains(parsed.errorCode)) {
      return ApiException(
        parsed.message,
        statusCode: 403,
        errorCode: parsed.errorCode,
        fieldErrors: parsed.fieldErrors,
      );
    }
    return const ForbiddenException();
  }

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
