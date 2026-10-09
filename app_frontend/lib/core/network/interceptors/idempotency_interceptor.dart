import 'package:dio/dio.dart';
import 'package:hawa_app/core/network/api_paths.dart';
import 'package:hawa_app/core/utils/ids.dart';

/// #2: `Idempotency-Key` on POST/PUT/PATCH/DELETE. Outbox calls pass the op id in
/// `extra['idempotency_key']`; other calls get one generated once and stored in `extra`, so the
/// key stays the same across retries of the same request.
class IdempotencyInterceptor extends Interceptor {
  static const header = 'Idempotency-Key';
  static const extraKey = 'idempotency_key';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (ApiPaths.isMutating(options.method) && !ApiPaths.isAuthCall(options.path)) {
      final key =
          options.extra[extraKey] as String? ?? options.headers[header] as String? ?? newId();
      options
        ..extra[extraKey] = key
        ..headers[header] = key;
    }
    handler.next(options);
  }
}
