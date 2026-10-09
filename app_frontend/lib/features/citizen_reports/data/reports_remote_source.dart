import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hawa_api/hawa_api.dart' as api;
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/core/network/fake/fake_backend.dart';
import 'package:hawa_app/core/network/fake/fake_backend_provider.dart';
import 'package:hawa_app/core/network/fake/fake_call.dart';
import 'package:hawa_app/core/network/hawa_api_provider.dart';
import 'package:hawa_app/core/network/interceptors/problem_json_interceptor.dart';
import 'package:hawa_app/core/storage/secure_token_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reports_remote_source.g.dart';

/// `GET /v1/reports/mine` and `GET /v1/reports/{id}` as plain JSON (cached as-is). Creating a
/// report goes through the outbox (`photo_upload` → `report_submit`), not through this source.
abstract interface class ReportsRemoteSource {
  Future<Map<String, Object?>> mine();

  Future<Map<String, Object?>> get(String id);
}

class HttpReportsRemoteSource implements ReportsRemoteSource {
  HttpReportsRemoteSource(this._api);

  final api.HawaApi _api;

  static Map<String, Object?> _plain(Object o) => jsonDecode(jsonEncode(o)) as Map<String, Object?>;

  @override
  Future<Map<String, Object?>> mine() async {
    try {
      return _plain((await _api.getReportsApi().reportsMine(limit: 50)).data!.toJson());
    } on DioException catch (e) {
      throw failureOf(e);
    }
  }

  @override
  Future<Map<String, Object?>> get(String id) async {
    try {
      return _plain((await _api.getReportsApi().reportsGet(id: id)).data!.toJson());
    } on DioException catch (e) {
      throw failureOf(e);
    }
  }
}

class FakeReportsRemoteSource implements ReportsRemoteSource {
  FakeReportsRemoteSource(this._backend, this._tokens);

  final FakeBackend _backend;
  final TokenStore _tokens;

  @override
  Future<Map<String, Object?>> mine() =>
      fakeCall(() async => _backend.reportsMine(token: await _tokens.readAccess()));

  @override
  Future<Map<String, Object?>> get(String id) =>
      fakeCall(() async => _backend.reportGet(id, token: await _tokens.readAccess()));
}

/// The backend has no report endpoints yet: fake unless `citizen_reports` is in REAL_FEATURES.
@Riverpod(keepAlive: true)
ReportsRemoteSource reportsRemoteSource(Ref ref) => Env.isFake('citizen_reports')
    ? FakeReportsRemoteSource(ref.watch(fakeBackendProvider), ref.watch(tokenStoreProvider))
    : HttpReportsRemoteSource(ref.watch(hawaApiProvider));
