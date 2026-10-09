import 'dart:async';

import 'package:hawa_app/core/realtime/event_deduper.dart';
import 'package:hawa_app/core/realtime/ws_client.dart';
import 'package:hawa_app/core/realtime/ws_message.dart';
import 'package:hawa_app/core/sync/sync_triggers.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'realtime_dispatcher.g.dart';

typedef RealtimeHandler = Future<void> Function(WsMessage message);

/// Routes realtime events by `type` prefix to feature appliers (registered by the data layers),
/// after the 10-minute dedupe. Unknown types are logged and ignored. A (re)connect or
/// `sys.resync` fires the gap-fill trigger: the WebSocket is not replayable (§10.1).
class RealtimeDispatcher {
  RealtimeDispatcher({required this.deduper, required this.onResync});

  final EventDeduper deduper;
  final void Function() onResync;
  final _handlers = <(String, RealtimeHandler)>[];
  static final _log = Logger('realtime');

  /// [typePrefix] such as `task.` or `alert.`. Several features may listen to one prefix.
  void on(String typePrefix, RealtimeHandler handler) => _handlers.add((typePrefix, handler));

  Future<void> dispatch(WsMessage message) async {
    if (message.isSys) {
      if (message.type == 'resync') onResync();
      return;
    }
    if (deduper.isDuplicate(message.dedupeKey)) return;
    var handled = false;
    for (final (prefix, handler) in _handlers) {
      if (!message.type.startsWith(prefix)) continue;
      handled = true;
      try {
        await handler(message);
      } on Object catch (e, st) {
        _log.warning('handler $prefix failed for ${message.type}', e, st);
      }
    }
    if (!handled) _log.fine('ignored realtime type ${message.type}');
  }
}

@Riverpod(keepAlive: true)
RealtimeDispatcher realtimeDispatcher(Ref ref) {
  final dispatcher = RealtimeDispatcher(
    deduper: ref.watch(eventDeduperProvider),
    onResync: () => ref.read(syncTriggersProvider.notifier).fire(SyncTriggerKind.wsReconnected),
  );
  final client = ref.watch(realtimeClientProvider);
  final subs = <StreamSubscription<Object?>>[
    client.messages.listen((m) => unawaited(dispatcher.dispatch(m))),
    client.status.listen((s) {
      if (s == RealtimeStatus.connected) {
        ref.read(syncTriggersProvider.notifier).fire(SyncTriggerKind.wsReconnected);
      }
    }),
  ];
  ref.onDispose(() {
    for (final s in subs) {
      unawaited(s.cancel());
    }
  });
  return dispatcher;
}

/// Connection state for the UI (live dot / polling).
@riverpod
Stream<RealtimeStatus> realtimeStatus(Ref ref) => ref.watch(realtimeClientProvider).status;
