import 'package:dio/dio.dart';
import 'package:hawa_app/core/network/api_paths.dart';
import 'package:hawa_app/core/storage/secure_token_store.dart';

/// Calls `POST /v1/auth/refresh` (implemented in features/auth/data on a bare Dio): rotates the
/// tokens in the token store and throws when the session cannot be refreshed.
typedef TokenRefresher = Future<void> Function();

/// Called when the refresh token is rejected: the router sends the user to login and the
/// outbox is kept for the same user (ARCHITECTURE §6.3).
typedef SessionExpired = void Function();

/// One refresh at a time for everyone (two concurrent 401s → one refresh call).
class SingleFlightRefresh {
  SingleFlightRefresh(this._refresher);

  final TokenRefresher _refresher;
  Future<void>? _inFlight;

  Future<void> run() => _inFlight ??= _refresher().whenComplete(() => _inFlight = null);
}

/// #4: on `401` from a non-auth endpoint, refresh once (single-flight) and replay the request
/// once with the new token. On refresh failure: the session-expired callback, and pass the error on.
class RefreshInterceptor extends QueuedInterceptor {
  RefreshInterceptor(this._tokens, this._refresh, this._dio, this._session);

  final TokenStore _tokens;
  final SingleFlightRefresh _refresh;
  final Dio _dio;
  final SessionExpired _session;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final opts = err.requestOptions;
    final isRetry = opts.extra['after_refresh'] == true;
    if (err.response?.statusCode != 401 || isRetry || ApiPaths.isAuthCall(opts.path)) {
      return handler.next(err);
    }
    try {
      final sentWith = opts.headers['Authorization'] as String?;
      final current = 'Bearer ${await _tokens.readAccess()}';
      if (sentWith == current) {
        // Nobody refreshed since this request left: refresh once for everyone.
        await _refresh.run();
      }
      opts
        ..extra['after_refresh'] = true
        ..headers['Authorization'] = 'Bearer ${await _tokens.readAccess()}';
      return handler.resolve(await _dio.fetch<Object?>(opts));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.requestOptions.path.contains(ApiPaths.refresh)) {
        _session();
      }
      return handler.next(e);
    } on Object {
      _session();
      return handler.next(err);
    }
  }
}
