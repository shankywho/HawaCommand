import 'package:dio/dio.dart';

/// Dev tools "Go offline": every request fails like a dropped connection.
class ForcedOfflineInterceptor extends Interceptor {
  ForcedOfflineInterceptor(this.isForcedOffline);

  final bool Function() isForcedOffline;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (isForcedOffline()) {
      return handler.reject(
        DioException.connectionError(requestOptions: options, reason: 'forced offline (dev)'),
      );
    }
    handler.next(options);
  }
}
