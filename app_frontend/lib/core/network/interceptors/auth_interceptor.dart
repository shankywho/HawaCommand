import 'package:dio/dio.dart';
import 'package:hawa_app/core/network/api_paths.dart';
import 'package:hawa_app/core/network/interceptors/refresh_interceptor.dart';
import 'package:hawa_app/core/storage/secure_token_store.dart';

/// #3: `Authorization: Bearer <access>`. If the token expires in under 60 s, waits for the
/// shared single-flight refresh first.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokens, this._refresh, {DateTime Function()? now})
    : _now = now ?? (() => DateTime.now().toUtc());

  final TokenStore _tokens;
  final SingleFlightRefresh _refresh;
  final DateTime Function() _now;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (ApiPaths.isAuthCall(options.path) &&
        !options.path.endsWith('/logout') &&
        !options.path.endsWith('/switch-role')) {
      return handler.next(options);
    }
    final exp = await _tokens.readAccessExpiry();
    if (exp != null && exp.difference(_now()) < const Duration(seconds: 60)) {
      try {
        await _refresh.run();
      } on Object {
        // The 401 path handles an expired session.
      }
    }
    final access = await _tokens.readAccess();
    if (access != null) options.headers['Authorization'] = 'Bearer $access';
    handler.next(options);
  }
}
