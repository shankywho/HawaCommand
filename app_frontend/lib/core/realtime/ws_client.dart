import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/core/network/dio_provider.dart';
import 'package:hawa_app/core/network/fake/fake_backend.dart';
import 'package:hawa_app/core/network/fake/fake_backend_provider.dart';
import 'package:hawa_app/core/network/interceptors/refresh_interceptor.dart';
import 'package:hawa_app/core/realtime/ws_message.dart';
import 'package:hawa_app/core/storage/secure_token_store.dart';
import 'package:hawa_app/core/utils/ids.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'ws_client.g.dart';

enum RealtimeStatus { disconnected, connecting, connected, reconnecting }

/// Realtime source for `tasks:me` and `alerts:me` (foreground only; FCM covers background).
abstract interface class RealtimeClient {
  Stream<WsMessage> get messages;

  Stream<RealtimeStatus> get status;

  RealtimeStatus get current;

  void connect();

  void disconnect();
}

/// `GET /v1/ws?token=<JWT>` (API.md §20). Heartbeat 25 s, reconnect with full-jitter backoff
/// 1 s → 30 s (reset after 60 s healthy), close 4401 → refresh then reconnect, `sys.resync` →
/// refetch. Falls back to "polling" (no WS) after 5 failures in 2 min; failure matrix row 13.
class WsClient implements RealtimeClient {
  WsClient({
    required this.url,
    required this.tokens,
    required this.refresh,
    this.channels = const ['tasks:me', 'alerts:me'],
    Random? random,
  }) : _random = random ?? Random();

  final String url;
  final TokenStore tokens;
  final SingleFlightRefresh refresh;
  final List<String> channels;
  final Random _random;
  static final _log = Logger('ws');

  final _messages = StreamController<WsMessage>.broadcast();
  final _status = StreamController<RealtimeStatus>.broadcast();
  RealtimeStatus _current = RealtimeStatus.disconnected;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _ping;
  Timer? _silence;
  Timer? _retry;
  Timer? _healthy;
  bool _wanted = false;
  int _attempt = 0;
  final _failures = <DateTime>[];

  @override
  Stream<WsMessage> get messages => _messages.stream;

  @override
  Stream<RealtimeStatus> get status => _status.stream;

  @override
  RealtimeStatus get current => _current;

  @override
  void connect() {
    _wanted = true;
    if (_channel != null || _retry != null) return;
    unawaited(_open());
  }

  @override
  void disconnect() {
    _wanted = false;
    _retry?.cancel();
    _retry = null;
    _teardown(code: 1000);
    _set(RealtimeStatus.disconnected);
  }

  Future<void> _open() async {
    _retry = null;
    if (!_wanted) return;
    _set(_attempt == 0 ? RealtimeStatus.connecting : RealtimeStatus.reconnecting);
    final token = await tokens.readAccess();
    if (token == null) return _scheduleRetry();
    final uri = Uri.parse(url).replace(queryParameters: {'token': token});
    try {
      final socket = await WebSocket.connect(uri.toString()).timeout(const Duration(seconds: 10));
      final channel = IOWebSocketChannel(socket);
      _channel = channel;
      _sub = channel.stream.listen(
        _onFrame,
        onDone: () => _onClosed(socket.closeCode),
        onError: (Object _) => _onClosed(null),
      );
      channel.sink.add(WsOps.subscribe(channels, id: 'c1'));
      _ping = Timer.periodic(
        const Duration(seconds: 25),
        (_) => channel.sink.add(WsOps.ping(newId())),
      );
      _armSilence();
      _healthy = Timer(const Duration(seconds: 60), () => _attempt = 0);
      _set(RealtimeStatus.connected);
    } on Object catch (e) {
      _log.fine('connect failed', e);
      _onClosed(null);
    }
  }

  void _onFrame(dynamic raw) {
    _armSilence();
    final msg = WsMessage.tryParse(raw);
    if (msg == null) return;
    if (msg.isSys && msg.type == 'ping') {
      _channel?.sink.add(WsOps.pong());
      return;
    }
    if (msg.isSys && msg.type == 'token_expiring') {
      unawaited(_reauth());
      return;
    }
    _messages.add(msg);
  }

  Future<void> _reauth() async {
    try {
      await refresh.run();
      final token = await tokens.readAccess();
      if (token != null) _channel?.sink.add(WsOps.auth(token));
    } on Object {
      _teardown(code: 1000);
    }
  }

  /// Nothing for 35 s → reconnect.
  void _armSilence() {
    _silence?.cancel();
    _silence = Timer(const Duration(seconds: 35), () => _onClosed(null));
  }

  void _onClosed(int? code) {
    _teardown();
    if (!_wanted) return;
    if (code == 4401) {
      unawaited(refresh.run().then((_) => _open(), onError: (Object _) => _scheduleRetry()));
      return;
    }
    if (code == 4400 || code == 4403) {
      _set(RealtimeStatus.disconnected);
      _wanted = false; // client bug or stale scope: do not loop
      return;
    }
    _scheduleRetry(minDelay: code == 1013 ? const Duration(seconds: 5) : Duration.zero);
  }

  void _scheduleRetry({Duration minDelay = Duration.zero}) {
    final now = DateTime.now();
    _failures
      ..add(now)
      ..removeWhere((t) => now.difference(t) > const Duration(minutes: 2));
    if (_failures.length >= 5) {
      // Proxy blocks upgrades: rely on polling until the next resume.
      _wanted = false;
      _set(RealtimeStatus.disconnected);
      return;
    }
    _attempt++;
    final cap = min(30, pow(2, _attempt).toInt());
    var delay = Duration(milliseconds: _random.nextInt(cap * 1000 + 1));
    if (delay < minDelay) delay = minDelay;
    _set(RealtimeStatus.reconnecting);
    _retry = Timer(delay, () => unawaited(_open()));
  }

  void _teardown({int? code}) {
    _ping?.cancel();
    _silence?.cancel();
    _healthy?.cancel();
    unawaited(_sub?.cancel());
    _sub = null;
    if (code != null) unawaited(_channel?.sink.close(code));
    _channel = null;
  }

  void _set(RealtimeStatus s) {
    if (_current == s) return;
    _current = s;
    if (!_status.isClosed) _status.add(s);
  }

  void dispose() {
    disconnect();
    unawaited(_messages.close());
    unawaited(_status.close());
  }
}

/// Fake realtime: the in-app fake backend's events for the signed-in session.
class FakeRealtimeClient implements RealtimeClient {
  FakeRealtimeClient(this.backend, this.tokens);

  final FakeBackend backend;
  final TokenStore tokens;
  final _messages = StreamController<WsMessage>.broadcast();
  final _status = StreamController<RealtimeStatus>.broadcast();
  StreamSubscription<Map<String, Object?>>? _sub;
  RealtimeStatus _current = RealtimeStatus.disconnected;

  @override
  Stream<WsMessage> get messages => _messages.stream;

  @override
  Stream<RealtimeStatus> get status => _status.stream;

  @override
  RealtimeStatus get current => _current;

  @override
  void connect() {
    if (_sub != null) return;
    unawaited(() async {
      final token = await tokens.readAccess();
      _sub = backend.eventsFor(token: token).listen((e) {
        if (backend.offline) return;
        final msg = WsMessage.tryParse(e);
        if (msg != null && msg.data['push_only'] != true) _messages.add(msg);
      });
      _set(RealtimeStatus.connected);
    }());
  }

  @override
  void disconnect() {
    unawaited(_sub?.cancel());
    _sub = null;
    _set(RealtimeStatus.disconnected);
  }

  void _set(RealtimeStatus s) {
    _current = s;
    if (!_status.isClosed) _status.add(s);
  }

  void dispose() {
    disconnect();
    unawaited(_messages.close());
    unawaited(_status.close());
  }
}

@Riverpod(keepAlive: true)
RealtimeClient realtimeClient(Ref ref) {
  final tokens = ref.watch(tokenStoreProvider);
  if (Env.isFake('driver_route') || Env.isFake('alerts')) {
    final fake = FakeRealtimeClient(ref.watch(fakeBackendProvider), tokens);
    ref.onDispose(fake.dispose);
    return fake;
  }
  final ws = WsClient(
    url: Env.wsUrl,
    tokens: tokens,
    refresh: ref.watch(singleFlightRefreshProvider),
  );
  ref.onDispose(ws.dispose);
  return ws;
}
