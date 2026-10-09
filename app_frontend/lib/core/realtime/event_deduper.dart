import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_deduper.g.dart';

/// 10-minute dedupe window shared by the WebSocket and FCM (ARCHITECTURE §10.1, SCREENS §9).
class EventDeduper {
  EventDeduper({this.window = const Duration(minutes: 10), DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Duration window;
  final DateTime Function() _now;
  final _seen = <String, DateTime>{};

  /// True when [key] was already seen within the window (and records it otherwise).
  bool isDuplicate(String key) {
    final now = _now();
    _seen.removeWhere((_, at) => now.difference(at) > window);
    if (_seen.containsKey(key)) return true;
    _seen[key] = now;
    return false;
  }
}

@Riverpod(keepAlive: true)
EventDeduper eventDeduper(Ref ref) => EventDeduper();
