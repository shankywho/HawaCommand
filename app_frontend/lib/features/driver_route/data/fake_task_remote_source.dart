import 'package:hawa_api/hawa_api.dart' as api;
import 'package:hawa_app/core/network/fake/fake_backend.dart';
import 'package:hawa_app/core/network/fake/fake_call.dart';
import 'package:hawa_app/core/storage/secure_token_store.dart';
import 'package:hawa_app/features/driver_route/data/task_remote_source.dart';

/// (dev) `tasks_mine_driver.json`: 6 simulated stops; sprays come from Dev tools ("Simulate
/// HawaTag spray") through the fake backend's `task.*` events.
class FakeTaskRemoteSource implements TaskRemoteSource {
  FakeTaskRemoteSource(this._backend, this._tokens);

  final FakeBackend _backend;
  final TokenStore _tokens;

  @override
  Future<api.TasksMineOut> fetchMine(String date) async => api.TasksMineOut.fromJson(
    await fakeCall(() async => _backend.tasksMine(date: date, token: await _tokens.readAccess())),
  );

  @override
  Future<api.TaskItem> fetchTask(String id) async => api.TaskItem.fromJson(
    await fakeCall(() async => _backend.taskGet(id, token: await _tokens.readAccess())),
  );
}
