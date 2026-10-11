import 'package:dio/dio.dart';
import 'package:hawa_app/core/network/dio_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'command_center_api.g.dart';

/// Read-only client for the endpoints the HawaCommand backend serves today (`/v1/twin`,
/// `/v1/hotspots`, `/v1/forecast`, `/v1/alerts`, `/v1/devices`, `/v1/impact`). They are public
/// reads, so this uses the bare Dio: no bearer token, no idempotency key.
///
/// The field contract (`hawa_api`, API.md) covers what the backend does not serve yet; features pick
/// per call which one to use through `Env.isFake`.
class CommandCenterApi {
  CommandCenterApi(this._dio);

  final Dio _dio;

  /// Max cells per `/v1/twin` call (server `limit` cap).
  static const twinPageLimit = 2000;

  Future<Map<String, Object?>> twin({String? bbox, int limit = twinPageLimit}) => _get('/v1/twin', {
    'limit': limit,
    'bbox': ?bbox,
  });

  Future<Map<String, Object?>> hotspots({int hour = 0, String? ward}) => _get('/v1/hotspots', {
    'hour': hour,
    'ward': ?ward,
  });

  Future<Map<String, Object?>> forecast({String? cellId}) =>
      _get(cellId == null ? '/v1/forecast' : '/v1/forecast/$cellId', const {});

  Future<Map<String, Object?>> safeWindow({String persona = 'general'}) =>
      _get('/v1/citizen/safe-window', {'persona': persona});

  Future<Map<String, Object?>> alerts() => _get('/v1/alerts', const {});

  /// Live HawaTag fleet (first) plus the simulated demo fleet, and verified interventions.
  Future<Map<String, Object?>> liveOperations() => _get('/v1/citizen/live-operations', const {});

  Future<Map<String, Object?>> devices() => _get('/v1/devices', const {});

  Future<Map<String, Object?>> impact() => _get('/v1/impact', const {});

  Future<bool> healthy() async {
    try {
      final res = await _dio.get<Object?>(
        '/healthz',
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      return res.statusCode == 200;
    } on Object {
      return false;
    }
  }

  Future<Map<String, Object?>> _get(String path, Map<String, Object?> query) async {
    final res = await _dio.get<Map<String, Object?>>(path, queryParameters: query);
    return res.data ?? const {};
  }
}

@Riverpod(keepAlive: true)
CommandCenterApi commandCenterApi(Ref ref) => CommandCenterApi(ref.watch(bareDioProvider));

/// Third-party services (road router, place search): no auth, no request ids, an honest
/// User-Agent (OSRM/Photon usage policies). Never sends anything but the query itself.
@Riverpod(keepAlive: true)
Dio externalDio(Ref ref) => Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    headers: {
      'User-Agent': 'HawaCommand-field/0.1 (in.hawacommand.field)',
      'Accept': 'application/json',
    },
  ),
);
