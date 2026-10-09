import 'package:dio/dio.dart';
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/core/network/connectivity_service.dart';
import 'package:hawa_app/core/network/interceptors/auth_interceptor.dart';
import 'package:hawa_app/core/network/interceptors/forced_offline_interceptor.dart';
import 'package:hawa_app/core/network/interceptors/idempotency_interceptor.dart';
import 'package:hawa_app/core/network/interceptors/logging_interceptor.dart';
import 'package:hawa_app/core/network/interceptors/problem_json_interceptor.dart';
import 'package:hawa_app/core/network/interceptors/refresh_interceptor.dart';
import 'package:hawa_app/core/network/interceptors/request_id_interceptor.dart';
import 'package:hawa_app/core/network/interceptors/retry_interceptor.dart';
import 'package:hawa_app/core/network/server_clock.dart';
import 'package:hawa_app/core/storage/secure_token_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_provider.g.dart';

/// Implemented by features/auth (refresh on a bare Dio); overridden in app/providers.dart.
@Riverpod(keepAlive: true)
TokenRefresher tokenRefresher(Ref ref) =>
    throw UnimplementedError('tokenRefresherProvider is overridden in app/providers.dart');

/// Implemented by the session controller; overridden in app/providers.dart.
@Riverpod(keepAlive: true)
SessionExpired sessionExpired(Ref ref) =>
    throw UnimplementedError('sessionExpiredProvider is overridden in app/providers.dart');

@Riverpod(keepAlive: true)
SingleFlightRefresh singleFlightRefresh(Ref ref) =>
    SingleFlightRefresh(ref.watch(tokenRefresherProvider));

/// The app's Dio with the interceptor chain in order (ARCHITECTURE §6.2). Request hooks run in
/// insertion order; error hooks too.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );
  final tokens = ref.watch(tokenStoreProvider);
  final refresh = ref.watch(singleFlightRefreshProvider);
  dio.interceptors.addAll([
    if (!Env.isProd) ForcedOfflineInterceptor(() => ref.read(forcedOfflineProvider)),
    RequestIdInterceptor(),
    IdempotencyInterceptor(),
    AuthInterceptor(tokens, refresh),
    RefreshInterceptor(tokens, refresh, dio, ref.watch(sessionExpiredProvider)),
    RetryInterceptor(dio),
    ProblemJsonInterceptor(),
    LoggingInterceptor(serverClock: ref.watch(serverClockProvider), enabled: !Env.isProd),
  ]);
  return dio;
}

/// Dio without auth or idempotency: the S3 presigned upload (our token must never reach S3)
/// and the token refresh call.
@Riverpod(keepAlive: true)
Dio bareDio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 60),
    ),
  );
  dio.interceptors.addAll([
    if (!Env.isProd) ForcedOfflineInterceptor(() => ref.read(forcedOfflineProvider)),
    RequestIdInterceptor(),
    ProblemJsonInterceptor(),
    LoggingInterceptor(serverClock: ref.watch(serverClockProvider), enabled: !Env.isProd),
  ]);
  return dio;
}
