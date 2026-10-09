import 'package:clock/clock.dart';

/// A controllable clock for tests: set [current] or [advance] it.
class FakeClock extends Clock {
  FakeClock(this.current) : super();

  DateTime current;

  @override
  DateTime now() => current;

  void advance(Duration d) => current = current.add(d);
}
