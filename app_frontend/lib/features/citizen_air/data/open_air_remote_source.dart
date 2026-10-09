import 'package:dio/dio.dart';
import 'package:hawa_api/hawa_api.dart' as api;
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/core/network/command_center_api.dart';
import 'package:hawa_app/core/network/fake/fake_backend_provider.dart';
import 'package:hawa_app/core/network/hawa_api_provider.dart';
import 'package:hawa_app/core/network/interceptors/problem_json_interceptor.dart';
import 'package:hawa_app/features/citizen_air/data/command_center_open_air_source.dart';
import 'package:hawa_app/features/citizen_air/data/fake_open_air_remote_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'open_air_remote_source.g.dart';

/// `GET /open/v1/air?bbox=` (public open data, no auth).
// One interface so the fake and HTTP sources swap behind one provider (ARCHITECTURE §2).
// ignore: one_member_abstracts
abstract interface class OpenAirRemoteSource {
  /// [bbox] is `minLon,minLat,maxLon,maxLat` snapped to the 0.01° grid by the caller; the
  /// precise position is never part of it (SCREENS C1).
  Future<api.OpenAirOut> air(String bbox);
}

class HttpOpenAirRemoteSource implements OpenAirRemoteSource {
  HttpOpenAirRemoteSource(this._api);

  final api.HawaApi _api;

  @override
  Future<api.OpenAirOut> air(String bbox) async {
    try {
      return (await _api.getOpenDataApi().openAir(bbox: bbox)).data!;
    } on DioException catch (e) {
      throw failureOf(e);
    }
  }
}

/// Fake (fixtures) unless `citizen_air` is real. The backend does not serve `/open/v1/air` yet, so
/// "real" means the AI-ML twin adapter; set `OPEN_AIR_CONTRACT=true` once the endpoint ships.
@Riverpod(keepAlive: true)
OpenAirRemoteSource openAirRemoteSource(Ref ref) {
  final fallback = FakeOpenAirRemoteSource(ref.watch(fakeBackendProvider));
  if (Env.isFake('citizen_air')) return fallback;
  if (const bool.fromEnvironment('OPEN_AIR_CONTRACT')) {
    return HttpOpenAirRemoteSource(ref.watch(hawaApiProvider));
  }
  return CommandCenterOpenAirSource(ref.watch(commandCenterApiProvider), fallback);
}

