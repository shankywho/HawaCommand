import 'dart:io';

import 'package:hawa_app/core/utils/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'server_clock.g.dart';

/// Tracks the skew between the device clock and the server's `Date` header, so staleness and
/// displayed times use server time even when the phone clock is wrong (failure matrix row 15).
class ServerClock {
  ServerClock(this._clock);

  final Clock _clock;
  Duration _skew = Duration.zero;

  Duration get skew => _skew;

  /// Only skews over 2 minutes are applied; smaller ones are network jitter.
  void observe(String? dateHeader) {
    if (dateHeader == null) return;
    try {
      final server = HttpDate.parse(dateHeader);
      final diff = server.difference(_clock.now().toUtc());
      _skew = diff.abs() > const Duration(minutes: 2) ? diff : Duration.zero;
    } on HttpException {
      return;
    } on FormatException {
      return;
    }
  }

  DateTime now() => _clock.now().toUtc().add(_skew);
}

@Riverpod(keepAlive: true)
ServerClock serverClock(Ref ref) => ServerClock(ref.watch(appClockProvider));
