import 'dart:convert';

/// FCM data payload (ARCHITECTURE §10.3; proposed contract). Every value is a string on the wire.
class PushPayload {
  const PushPayload({
    required this.type,
    this.alertId,
    this.entityId,
    this.deepLink,
    this.role,
    this.lang,
    this.title,
    this.body,
    this.args = const {},
    this.isSimulated = false,
    this.sentAt,
    this.collapseKey,
  });

  /// Tolerant parse: missing or malformed fields become null; never throws.
  factory PushPayload.fromData(Map<String, Object?> data) {
    var args = const <String, Object?>{};
    final rawArgs = data['args'];
    if (rawArgs is String && rawArgs.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawArgs);
        if (decoded is Map) args = decoded.cast<String, Object?>();
      } on FormatException {
        args = const {};
      }
    } else if (rawArgs is Map) {
      args = rawArgs.cast<String, Object?>();
    }
    String? s(String k) {
      final v = data[k];
      return v == null || v.toString().isEmpty ? null : v.toString();
    }

    return PushPayload(
      type: s('type') ?? s('kind') ?? 'unknown',
      alertId: s('alert_id'),
      entityId: s('entity_id'),
      deepLink: s('deep_link'),
      role: s('role'),
      lang: s('lang'),
      title: s('title'),
      body: s('body'),
      args: args,
      isSimulated: s('is_simulated') == 'true' || data['is_simulated'] == true,
      sentAt: DateTime.tryParse(s('sent_at') ?? s('created_at') ?? ''),
      collapseKey: s('collapse_key'),
    );
  }

  final String type;
  final String? alertId;
  final String? entityId;
  final String? deepLink;
  final String? role;
  final String? lang;
  final String? title;
  final String? body;
  final Map<String, Object?> args;
  final bool isSimulated;
  final DateTime? sentAt;
  final String? collapseKey;

  /// Shared dedupe key with the WebSocket path.
  String get dedupeKey => collapseKey ?? 'alerts:me|alert.requested|${alertId ?? entityId ?? ''}|';

  Map<String, String> toData() => {
    'type': type,
    'alert_id': ?alertId,
    'entity_id': ?entityId,
    'deep_link': ?deepLink,
    'role': ?role,
    'lang': ?lang,
    'title': ?title,
    'body': ?body,
    if (args.isNotEmpty) 'args': jsonEncode(args),
    'is_simulated': '$isSimulated',
    if (sentAt != null) 'sent_at': sentAt!.toIso8601String(),
    'collapse_key': ?collapseKey,
  };
}
