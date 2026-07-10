import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../error/app_exception.dart';
import '../storage/token_storage.dart';
import 'dio_retry_interceptor.dart';

Dio createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 12),
      headers: const {},
    ),
  );

  dio.interceptors.add(_AuthInterceptor());
  dio.interceptors.add(DioRetryInterceptor(dio, maxRetries: 2));
  dio.interceptors.add(_FullUrlLogger());

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: false,
      logPrint: (obj) => debugPrint(obj.toString()),
    ));
  }

  return dio;
}

/// Logs the full resolved request URL (method + uri) before sending.
class _FullUrlLogger extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[DIO] ${options.method} ${options.uri}');
    }
    handler.next(options);
  }
}

/// Adds JWT Bearer token to every request using the in-memory cache when warm.
class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = TokenStorage.cachedToken ?? await TokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}

/// Helper that wraps Dio calls and maps exceptions.
Future<T> apiCall<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (e) {
    throw mapDioException(e);
  }
}
