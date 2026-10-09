import 'package:dio/dio.dart';
import 'package:hawa_api/hawa_api.dart' as api;
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/core/network/fake/fake_backend_provider.dart';
import 'package:hawa_app/core/network/hawa_api_provider.dart';
import 'package:hawa_app/core/network/interceptors/problem_json_interceptor.dart';
import 'package:hawa_app/core/storage/secure_token_store.dart';
import 'package:hawa_app/features/driver_route/data/fake_task_remote_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_remote_source.g.dart';

/// `GET /v1/tasks/mine` and `GET /v1/tasks/{id}` in generated-client models.
abstract interface class TaskRemoteSource {
  Future<api.TasksMineOut> fetchMine(String date);

  Future<api.TaskItem> fetchTask(String id);
}

class HttpTaskRemoteSource implements TaskRemoteSource {
  HttpTaskRemoteSource(this._api);

  final api.HawaApi _api;

  @override
  Future<api.TasksMineOut> fetchMine(String date) async {
    try {
      return (await _api.getTasksApi().tasksMine(date: date)).data!;
    } on DioException catch (e) {
      throw failureOf(e);
    }
  }

  @override
  Future<api.TaskItem> fetchTask(String id) async {
    try {
      return (await _api.getTasksApi().tasksGet(id: id)).data!;
    } on DioException catch (e) {
      throw failureOf(e);
    }
  }
}

/// Fake (fixtures) when `USE_FAKE_API` or `FAKE_FEATURES` lists `driver_route`.
@Riverpod(keepAlive: true)
TaskRemoteSource taskRemoteSource(Ref ref) => Env.isFake('driver_route')
    ? FakeTaskRemoteSource(ref.watch(fakeBackendProvider), ref.watch(tokenStoreProvider))
    : HttpTaskRemoteSource(ref.watch(hawaApiProvider));
