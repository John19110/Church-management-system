import 'package:dio/dio.dart';

/// Retries transient connection failures without blocking the UI thread.
class DioRetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;

  DioRetryInterceptor(
    this.dio, {
    this.maxRetries = 2,
    this.retryDelay = const Duration(milliseconds: 800),
  });

  static const _retryKey = 'retryCount';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    final attempt = (err.requestOptions.extra[_retryKey] as int?) ?? 0;
    if (attempt >= maxRetries) {
      handler.next(err);
      return;
    }

    await Future<void>.delayed(retryDelay * (attempt + 1));

    final options = err.requestOptions;
    options.extra[_retryKey] = attempt + 1;

    try {
      final response = await dio.fetch(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}
