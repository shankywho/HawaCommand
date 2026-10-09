import 'dart:convert';
import 'dart:io';

import 'package:hawa_app/core/network/fake/fake_backend.dart';

/// Fixture base instant: 06:30 IST on the fixtures' service date, so no date rebasing happens.
final fixtureNow = DateTime.utc(2026, 11, 13, 1);

/// Reads `assets/fixtures/<path>` from disk (tests run from the package root).
Future<String> loadFixture(String path) => File('assets/fixtures/$path').readAsString();

Map<String, Object?> fixtureJson(String path) =>
    (jsonDecode(File('assets/fixtures/$path').readAsStringSync()) as Map).cast<String, Object?>();

/// A fake backend on the real fixtures with no latency. Dispose it (cancels report timers).
FakeBackend testBackend({DateTime Function()? now}) =>
    FakeBackend(load: loadFixture, now: now ?? () => fixtureNow, latency: Duration.zero);
