import 'package:church_app/core/error/app_exception.dart';
import 'package:church_app/core/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a DioException shaped like the API's ProblemDetails responses, e.g.
/// {"type":"AUTH_FAILED","title":"Authentication failed","status":401,"detail":"..."}
DioException _problemDetails({
  required int status,
  String? type,
  String title = 'Error',
  String detail = 'Something happened.',
}) {
  final options = RequestOptions(path: '/api/Account/login');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: <String, dynamic>{
        if (type != null) 'type': type,
        'title': title,
        'status': status,
        'detail': detail,
      },
    ),
  );
}

void main() {
  final en = AppLocalizations.forLocale(const Locale('en'));
  final ar = AppLocalizations.forLocale(const Locale('ar'));

  group('403 account-status codes are preserved, not flattened', () {
    test('ACCOUNT_PENDING keeps its error code and localizes', () {
      final mapped = mapDioException(_problemDetails(
        status: 403,
        type: 'ACCOUNT_PENDING',
        title: 'Forbidden',
        detail: 'Your account is waiting for approval from the church administrator.',
      ));

      expect(mapped, isA<ApiException>());
      expect((mapped as ApiException).errorCode, 'ACCOUNT_PENDING');
      expect(mapped.statusCode, 403);
      expect(userFriendlyMessage(mapped, en), en.accountPendingApproval);
      expect(userFriendlyMessage(mapped, ar), ar.accountPendingApproval);
    });

    test('ACCOUNT_REJECTED keeps its error code and localizes', () {
      final mapped = mapDioException(_problemDetails(
        status: 403,
        type: 'ACCOUNT_REJECTED',
        title: 'Forbidden',
        detail: 'Your registration request was rejected.',
      ));

      expect(mapped, isA<ApiException>());
      expect((mapped as ApiException).errorCode, 'ACCOUNT_REJECTED');
      expect(userFriendlyMessage(mapped, en), en.accountRejected);
      expect(userFriendlyMessage(mapped, ar), ar.accountRejected);
    });
  });

  group('genuine authorization failures still read as permission errors', () {
    test('403 FORBIDDEN maps to ForbiddenException', () {
      final mapped = mapDioException(_problemDetails(
        status: 403,
        type: 'FORBIDDEN',
        title: 'Forbidden',
        detail: 'Forbidden',
      ));

      expect(mapped, isA<ForbiddenException>());
      expect(mapped.message, "You don't have permission to perform this action.");
    });

    test('403 with no structured code maps to ForbiddenException', () {
      final mapped = mapDioException(_problemDetails(status: 403, title: 'Forbidden'));

      expect(mapped, isA<ForbiddenException>());
    });

    test('a pending code on a non-403 status is not treated as pending', () {
      final mapped = mapDioException(_problemDetails(
        status: 400,
        type: 'ACCOUNT_PENDING',
      ));

      expect(mapped, isNot(isA<ForbiddenException>()));
      expect(mapped.statusCode, 400);
    });
  });

  group('401 stays an authentication failure', () {
    test('AUTH_FAILED is credentials, not permission', () {
      final mapped = mapDioException(_problemDetails(
        status: 401,
        type: 'AUTH_FAILED',
        title: 'Authentication failed',
        detail: 'Invalid username or password.',
      ));

      expect(mapped, isA<ApiException>());
      expect((mapped as ApiException).errorCode, 'AUTH_FAILED');
      expect(mapped.statusCode, 401);
      expect(userFriendlyMessage(mapped, en), en.invalidCredentialsPleaseTryAgain);
    });

    test('401 without a code is an expired session', () {
      final mapped = mapDioException(_problemDetails(status: 401, title: 'Unauthorized'));

      expect(mapped, isA<UnauthorizedException>());
      expect(userFriendlyMessage(mapped, en), en.sessionExpiredPleaseSignIn);
    });
  });

  group('other error handling is unchanged', () {
    test('404 keeps its parsed message and status', () {
      final mapped = mapDioException(_problemDetails(
        status: 404,
        type: 'NOT_FOUND',
        detail: 'Classroom was not found.',
      ));

      expect(mapped, isA<ApiException>());
      expect(mapped.statusCode, 404);
      expect((mapped as ApiException).errorCode, 'NOT_FOUND');
    });

    test('connection timeout maps to timeout, not permission', () {
      final mapped = mapDioException(DioException(
        requestOptions: RequestOptions(path: '/api/Member'),
        type: DioExceptionType.connectionTimeout,
      ));

      expect(mapped, isA<ApiTimeoutException>());
    });

    test('connection error maps to network error', () {
      final mapped = mapDioException(DioException(
        requestOptions: RequestOptions(path: '/api/Member'),
        type: DioExceptionType.connectionError,
      ));

      expect(mapped, isA<NetworkException>());
    });
  });
}
