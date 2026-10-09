import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:clock/clock.dart' show Clock;

part 'clock.g.dart';

/// Injectable time source; tests override it with `Clock.fixed(...)`.
@Riverpod(keepAlive: true)
Clock appClock(Ref ref) => const Clock();
