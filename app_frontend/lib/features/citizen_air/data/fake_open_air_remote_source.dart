import 'package:hawa_api/hawa_api.dart' as api;
import 'package:hawa_app/core/network/fake/fake_backend.dart';
import 'package:hawa_app/core/network/fake/fake_call.dart';
import 'package:hawa_app/features/citizen_air/data/open_air_remote_source.dart';

/// Open air from `open_air_bbox.json` (the fake re-centres its grid on the requested box).
class FakeOpenAirRemoteSource implements OpenAirRemoteSource {
  FakeOpenAirRemoteSource(this._backend);

  final FakeBackend _backend;

  @override
  Future<api.OpenAirOut> air(String bbox) async =>
      api.OpenAirOut.fromJson(await fakeCall(() => _backend.openAir(bbox: bbox)));
}
