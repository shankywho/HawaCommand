import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hawa_api/hawa_api.dart' as api;
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/core/network/command_center_api.dart';
import 'package:hawa_app/core/network/fake/fake_backend.dart';
import 'package:hawa_app/core/network/fake/fake_backend_provider.dart';
import 'package:hawa_app/core/network/fake/fake_call.dart';
import 'package:hawa_app/core/network/hawa_api_provider.dart';
import 'package:hawa_app/core/network/interceptors/problem_json_interceptor.dart';
import 'package:hawa_app/core/storage/secure_token_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'school_remote_source.g.dart';

/// School reads as plain JSON (cached as-is): `schools/me`, safe window, indoor/outdoor, GRAP
/// outlook and the cell forecast.
abstract interface class SchoolRemoteSource {
  Future<Map<String, Object?>> me();

  Future<Map<String, Object?>> safeWindow(String schoolId, String date);

  Future<Map<String, Object?>> indoorOutdoor(String schoolId);

  Future<Map<String, Object?>> grapOutlook(String ward);

  Future<Map<String, Object?>> forecast(String cellId);
}

Map<String, Object?> _plain(Object o) => jsonDecode(jsonEncode(o)) as Map<String, Object?>;

class HttpSchoolRemoteSource implements SchoolRemoteSource {
  HttpSchoolRemoteSource(this._api);

  final api.HawaApi _api;

  Future<Map<String, Object?>> _guard(Future<Object?> Function() call) async {
    try {
      return _plain((await call())!);
    } on DioException catch (e) {
      throw failureOf(e);
    }
  }

  @override
  Future<Map<String, Object?>> me() =>
      _guard(() async => (await _api.getSchoolsApi().schoolsMe()).data!.toJson());

  @override
  Future<Map<String, Object?>> safeWindow(String schoolId, String date) => _guard(
    () async =>
        (await _api.getSchoolsApi().schoolsSafeWindow(id: schoolId, date: date)).data!.toJson(),
  );

  @override
  Future<Map<String, Object?>> indoorOutdoor(String schoolId) => _guard(
    () async => (await _api.getSchoolsApi().schoolsIndoorOutdoor(id: schoolId)).data!.toJson(),
  );

  @override
  Future<Map<String, Object?>> grapOutlook(String ward) =>
      _guard(() async => (await _api.getGrapApi().grapOutlook(ward: ward)).data!.toJson());

  @override
  Future<Map<String, Object?>> forecast(String cellId) =>
      _guard(() async => (await _api.getForecastApi().forecastGet(cellId: cellId)).data!.toJson());
}

class FakeSchoolRemoteSource implements SchoolRemoteSource {
  FakeSchoolRemoteSource(this._backend, this._tokens);

  final FakeBackend _backend;
  final TokenStore _tokens;

  @override
  Future<Map<String, Object?>> me() =>
      fakeCall(() async => _backend.schoolsMe(token: await _tokens.readAccess()));

  @override
  Future<Map<String, Object?>> safeWindow(String schoolId, String date) => fakeCall(
    () async => _backend.safeWindow(schoolId, date: date, token: await _tokens.readAccess()),
  );

  @override
  Future<Map<String, Object?>> indoorOutdoor(String schoolId) =>
      fakeCall(() async => _backend.indoorOutdoor(schoolId, token: await _tokens.readAccess()));

  @override
  Future<Map<String, Object?>> grapOutlook(String ward) =>
      fakeCall(() async => _backend.grapOutlook(ward, token: await _tokens.readAccess()));

  @override
  Future<Map<String, Object?>> forecast(String cellId) =>
      fakeCall(() async => _backend.forecast(cellId, token: await _tokens.readAccess()));
}

/// The 72 h forecast from the live backend (`/v1/forecast/{cell_id}`, AI-ML P10/P50/P90),
/// reshaped to the contract `series: [{horizon_h, valid_at, p10, p50, p90}]`; everything else
/// from [inner] (the backend has no school endpoints yet).
class CommandCenterForecastSource implements SchoolRemoteSource {
  CommandCenterForecastSource(this._api, this.inner);

  final CommandCenterApi _api;
  final SchoolRemoteSource inner;

  @override
  Future<Map<String, Object?>> forecast(String cellId) async {
    try {
      return reshape(await _api.forecast(cellId: cellId));
    } on Object catch (e) {
      throw failureOf(e);
    }
  }

  /// Pure (unit tested).
  static Map<String, Object?> reshape(Map<String, Object?> json) {
    final issued =
        DateTime.tryParse(json['issuedAt'] as String? ?? '')?.toUtc() ?? DateTime.now().toUtc();
    return {
      'issued_at': issued.toIso8601String(),
      'is_simulated': json['simulated'] as bool? ?? false,
      'series': [
        for (final p in (json['series'] as List<Object?>?) ?? const [])
          if (p is Map<String, Object?> && p['p50'] is num)
            () {
              final q = [
                p['p10'],
                p['p50'],
                p['p90'],
              ].whereType<num>().map((v) => v.toDouble()).toList()..sort();
              final h = (p['h'] as num?)?.toInt() ?? 0;
              return {
                'horizon_h': h,
                'valid_at': issued.add(Duration(hours: h)).toIso8601String(),
                'p10': q.first,
                'p50': (p['p50']! as num).toDouble(),
                'p90': q.last,
              };
            }(),
      ],
    };
  }

  @override
  Future<Map<String, Object?>> me() => inner.me();

  @override
  Future<Map<String, Object?>> safeWindow(String schoolId, String date) =>
      inner.safeWindow(schoolId, date);

  @override
  Future<Map<String, Object?>> indoorOutdoor(String schoolId) => inner.indoorOutdoor(schoolId);

  @override
  Future<Map<String, Object?>> grapOutlook(String ward) => inner.grapOutlook(ward);
}

@Riverpod(keepAlive: true)
SchoolRemoteSource schoolRemoteSource(Ref ref) {
  final base = Env.isFake('school')
      ? FakeSchoolRemoteSource(ref.watch(fakeBackendProvider), ref.watch(tokenStoreProvider))
      : HttpSchoolRemoteSource(ref.watch(hawaApiProvider));
  if (Env.isFake('school_forecast')) return base;
  return CommandCenterForecastSource(ref.watch(commandCenterApiProvider), base);
}
