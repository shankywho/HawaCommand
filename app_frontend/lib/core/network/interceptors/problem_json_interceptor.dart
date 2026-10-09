import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hawa_app/core/errors/failure.dart';

/// #6: parses `application/problem+json` into a typed [Failure] and sets it as
/// `DioException.error`, so data sources can rethrow `e.error`.
class ProblemJsonInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err.copyWith(error: toFailure(err)));
  }

  static Failure toFailure(DioException err) {
    final existing = err.error;
    if (existing is Failure) return existing;
    final requestId = err.requestOptions.extra['request_id'] as String?;
    switch (err.type) {
      case DioExceptionType.connectionError:
        return NetworkFailure(requestId: requestId);
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return TimeoutFailure(requestId: requestId);
      case DioExceptionType.badResponse:
        final response = err.response;
        final status = response?.statusCode ?? 0;
        final problem = _problem(response?.data, status);
        final retry = int.tryParse(response?.headers.value('retry-after') ?? '');
        return Failure.fromStatus(
          status,
          problem: problem,
          requestId: response?.headers.value('x-request-id') ?? requestId,
          retryAfter: retry == null ? null : Duration(seconds: retry),
        );
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return err.error is Exception && err.type == DioExceptionType.unknown
            ? NetworkFailure(requestId: requestId)
            : UnknownFailure(err.error ?? err.message ?? 'dio', requestId: requestId);
    }
  }

  static ProblemDetails? _problem(Object? data, int status) {
    var body = data;
    if (body is String && body.trim().startsWith('{')) {
      try {
        body = jsonDecode(body);
      } on FormatException {
        return null;
      }
    }
    if (body is Map) {
      return ProblemDetails.fromJson(body.cast<String, Object?>(), fallbackStatus: status);
    }
    return null;
  }
}

/// Unwraps the typed failure from a [DioException] (or any error).
Failure failureOf(Object error) {
  if (error is Failure) return error;
  if (error is DioException) return ProblemJsonInterceptor.toFailure(error);
  return UnknownFailure(error);
}
