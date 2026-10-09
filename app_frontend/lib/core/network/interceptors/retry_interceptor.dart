import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:hawa_app/core/network/interceptors/idempotency_interceptor.dart';

/// #5: short-term retry of transient errors (connection, timeout, 502/503/504, 429 honouring
/// `Retry-After`, `409 idempotency_in_progress`), at most 2 times with 0.5 s / 1.5 s + jitter.
/// Only for GET/PUT/DELETE and POSTs that carry an `Idempotency-Key`. Long-term retry belongs
/// to the outbox.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio, {Random? random, this.maxRetries = 2}) : _random = random ?? Random();

  final Dio _dio;
  final Random _random;
  final int maxRetries;

  static const _delays = [Duration(milliseconds: 500), Duration(milliseconds: 1500)];

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final opts = err.requestOptions;
    final attempt = (opts.extra['retry_attempt'] as int?) ?? 0;
    if (attempt >= maxRetries || !_retryable(err) || !_safeToRepeat(opts)) {
      return handler.next(err);
    }
    final retryAfter = _retryAfter(err.response);
    if (retryAfter != null && retryAfter > const Duration(seconds: 10)) {
      return handler.next(err); // long waits belong to the outbox backoff
    }
    final base = _delays[attempt.clamp(0, _delays.length - 1)];
    final jitter = Duration(milliseconds: _random.nextInt(250));
    await Future<void>.delayed(retryAfter ?? base + jitter);
    opts.extra['retry_attempt'] = attempt + 1;
    try {
      return handler.resolve(await _dio.fetch<Object?>(opts));
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _retryable(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return true;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode ?? 0;
        if (status == 429 || status == 502 || status == 503 || status == 504) return true;
        if (status == 409) {
          final data = err.response?.data;
          final code = data is Map ? data['code'] : null;
          return code == 'idempotency.in_progress' || code == 'idempotency_in_progress';
        }
        return false;
      case DioExceptionType.transformTimeout:
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return false;
    }
  }

  bool _safeToRepeat(RequestOptions opts) {
    final method = opts.method.toUpperCase();
    if (method == 'GET' || method == 'PUT' || method == 'DELETE') return true;
    return opts.headers[IdempotencyInterceptor.header] != null;
  }

  static Duration? _retryAfter(Response<dynamic>? response) {
    final value = response?.headers.value('retry-after');
    final seconds = value == null ? null : int.tryParse(value);
    return seconds == null ? null : Duration(seconds: seconds);
  }
}
