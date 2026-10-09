import 'package:dio/dio.dart';
import 'package:hawa_app/core/utils/ids.dart';

/// #1: a new UUIDv7 `X-Request-Id` per attempt; `X-Correlation-Id` passes through if set.
class RequestIdInterceptor extends Interceptor {
  static const header = 'X-Request-Id';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final id = newId();
    options
      ..headers[header] = id
      ..extra['request_id'] = id;
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final echoed = response.headers.value(header);
    if (echoed != null) response.requestOptions.extra['request_id'] = echoed;
    handler.next(response);
  }
}
