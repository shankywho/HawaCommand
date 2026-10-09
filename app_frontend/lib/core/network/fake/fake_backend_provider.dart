import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hawa_app/core/network/connectivity_service.dart';
import 'package:hawa_app/core/network/fake/fake_backend.dart';
import 'package:hawa_app/core/utils/clock.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fake_backend_provider.g.dart';

/// The in-app fake backend (dev fake mode). Its state is saved to `fake_backend_state.json`
/// after every change, so a skipped stop stays skipped across app restarts on the same day.
@Riverpod(keepAlive: true)
FakeBackend fakeBackend(Ref ref) {
  final clock = ref.watch(appClockProvider);
  final backend = FakeBackend(
    load: (path) => rootBundle.loadString('assets/fixtures/$path'),
    now: () => clock.now().toUtc(),
  )..offline = ref.read(forcedOfflineProvider);
  ref
    ..listen(forcedOfflineProvider, (_, offline) => backend.offline = offline)
    ..onDispose(backend.dispose);
  unawaited(_FakeStatePersistence(backend).start());
  return backend;
}

class _FakeStatePersistence {
  _FakeStatePersistence(this.backend);

  final FakeBackend backend;
  Timer? _debounce;
  static final _log = Logger('fake');

  Future<File> _file() async =>
      File(p.join((await getApplicationDocumentsDirectory()).path, 'fake_backend_state.json'));

  Future<void> start() async {
    try {
      final file = await _file();
      if (file.existsSync()) {
        await backend.importState(
          (jsonDecode(await file.readAsString()) as Map).cast<String, Object?>(),
        );
      }
    } on Object catch (e) {
      _log.warning('fake state not restored', e);
    }
    backend.changes.listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), () => unawaited(_save()));
    });
  }

  Future<void> _save() async {
    try {
      await (await _file()).writeAsString(jsonEncode(backend.exportState()));
    } on Object catch (e) {
      _log.warning('fake state not saved', e);
    }
  }
}
