import 'dart:convert';

/// Server → client envelope (API.md §20.3): `{channel, type, event_id, seq, ts, data}`.
/// Parsing is tolerant: unknown fields are ignored, malformed frames return null.
class WsMessage {
  const WsMessage({
    required this.channel,
    required this.type,
    required this.data,
    this.eventId,
    this.seq,
    this.ts,
  });

  static WsMessage? tryParse(Object? raw) {
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! Map) return null;
      final channel = decoded['channel'];
      final type = decoded['type'];
      if (channel is! String || type is! String) return null;
      final data = decoded['data'];
      return WsMessage(
        channel: channel,
        type: type,
        eventId: decoded['event_id']?.toString(),
        seq: (decoded['seq'] as num?)?.toInt(),
        ts: DateTime.tryParse(decoded['ts']?.toString() ?? ''),
        data: data is Map ? data.cast<String, Object?>() : const {},
      );
    } on FormatException {
      return null;
    }
  }

  final String channel;
  final String type;
  final String? eventId;
  final int? seq;
  final DateTime? ts;
  final Map<String, Object?> data;

  bool get isSys => channel == 'sys';

  /// Dedupe key shared with FCM (ARCHITECTURE §10.1).
  String get dedupeKey =>
      '$channel|$type|${data['task_id'] ?? data['alert_id'] ?? data['report_id'] ?? ''}|${data['status'] ?? ''}';
}

/// Client → server ops (API.md §20.2).
abstract final class WsOps {
  static String subscribe(List<String> channels, {String? id}) =>
      jsonEncode({'op': 'subscribe', 'channels': channels, 'id': ?id});

  static String ping(String id) => jsonEncode({'op': 'ping', 'id': id});

  static String pong() => jsonEncode({'op': 'pong'});

  static String auth(String token) => jsonEncode({'op': 'auth', 'token': token});
}
