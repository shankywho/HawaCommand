import 'package:dio/dio.dart';
import 'package:hawa_app/core/errors/app_logger.dart';
import 'package:hawa_app/core/network/server_clock.dart';
import 'package:logging/logging.dart';

/// #7 (dev/staging): method, path, request id, status and duration. Bodies are not logged;
/// headers never are. Every line is redacted (tokens, phones, OTPs, presigned URLs). Also feeds
/// the server clock from `Date` headers.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({this.serverClock, this.enabled = true});

  final ServerClock? serverClock;
  final bool enabled;
  static final _log = Logger('http');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['started_at'] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    serverClock?.observe(response.headers.value('date'));
    _line(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    serverClock?.observe(err.response?.headers.value('date'));
    _line(err.requestOptions, err.response?.statusCode, error: err.type.name);
    handler.next(err);
  }

  void _line(RequestOptions o, int? status, {String? error}) {
    if (!enabled) return;
    final started = o.extra['started_at'] as int?;
    final ms = started == null ? '?' : '${DateTime.now().millisecondsSinceEpoch - started}';
    _log.fine(
      AppLogger.redact(
        '${o.method} ${o.uri.path} → ${status ?? error} ${ms}ms rid=${o.extra['request_id']}',
      ),
    );
  }
}
