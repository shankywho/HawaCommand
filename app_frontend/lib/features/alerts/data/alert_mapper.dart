import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:hawa_api/hawa_api.dart' as api;
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/features/alerts/domain/alert_kind.dart';
import 'package:hawa_app/features/alerts/domain/app_alert.dart';

/// `AlertItem` / WS `alert.*` data / drift rows → [AppAlert]. Rows written by the FCM background
/// handler carry the push payload in `payload_json`, so reading is tolerant of both shapes.
abstract final class AlertMapper {
  static const _unknownWire = 'unknown_default_open_api';

  /// Server alert → drift row. `payload_json` keeps the `AlertItem` JSON; the server's
  /// `read_at`/`acked_at` only overwrite local state when present (AlertDao.upsertAll).
  static AlertsTableCompanion toRow(api.AlertItem a) => AlertsTableCompanion.insert(
    id: a.id,
    kind: _wire(a.kind.value),
    audience: Value(_wire(a.audience.value)),
    title: a.title,
    body: a.body,
    lang: a.lang == api.Lang.hi ? 'hi' : 'en',
    deepLink: Value(a.deepLink),
    receivedAt: (a.sentAt ?? a.createdAt).toUtc(),
    readAt: Value(a.readAt?.toUtc()),
    ackedAt: Value(a.ackedAt?.toUtc()),
    expiresAt: Value(a.expiresAt?.toUtc()),
    isSimulated: Value(a.isSimulated),
    payloadJson: jsonEncode(a.toJson()),
  );

  /// WS `alert.requested` data `{alert_id, audience, kind, title, body, deep_link, entity_id,
  /// is_simulated, created_at, lang?, expires_at?}` → drift row, or null without an id.
  static AlertsTableCompanion? fromRealtime(
    Map<String, Object?> data, {
    required DateTime now,
    DateTime? eventTs,
  }) {
    final id = _str(data['alert_id']);
    if (id == null || id.isEmpty) return null;
    final created = _date(data['created_at']) ?? eventTs?.toUtc() ?? now.toUtc();
    final expires = _date(data['expires_at']);
    final simulated = _bool(data['is_simulated']);
    final lang = _str(data['lang']) == 'hi' ? 'hi' : 'en';
    final item = <String, Object?>{
      'id': id,
      'audience': _str(data['audience']) ?? '',
      'kind': _str(data['kind']) ?? AlertKind.unknown.wire,
      'status': 'delivered',
      'lang': lang,
      'title': _str(data['title']) ?? '',
      'body': _str(data['body']) ?? '',
      'created_at': created.toIso8601String(),
      'is_simulated': simulated,
      'deep_link': _str(data['deep_link']),
      'entity_id': _str(data['entity_id']),
      'pollutant': _str(data['pollutant']),
      'expires_at': expires?.toIso8601String(),
    }..removeWhere((_, v) => v == null);
    return AlertsTableCompanion.insert(
      id: id,
      kind: item['kind']! as String,
      audience: Value(item['audience']! as String),
      title: item['title']! as String,
      body: item['body']! as String,
      lang: lang,
      deepLink: Value(_str(data['deep_link'])),
      receivedAt: created,
      expiresAt: Value(expires),
      isSimulated: Value(simulated),
      payloadJson: jsonEncode(item),
    );
  }

  /// Drift row → domain.
  static AppAlert fromRow(AlertRow r) {
    final p = _decode(r.payloadJson);
    final audience = r.audience.isNotEmpty
        ? r.audience
        : (_str(p['audience']) ?? _str(p['role']) ?? '');
    final pollutant = _str(p['pollutant']);
    return AppAlert(
      id: r.id,
      kind: AlertKind.fromWire(r.kind),
      audience: audience == 'unknown' ? '' : audience,
      title: r.title,
      body: r.body,
      lang: r.lang == 'hi' ? 'hi' : 'en',
      createdAt: _date(p['created_at']) ?? _date(p['sent_at']) ?? r.receivedAt.toUtc(),
      receivedAt: r.receivedAt.toUtc(),
      deepLink: r.deepLink ?? _str(p['deep_link']),
      pollutant: pollutant == null ? null : Pollutant.fromWire(pollutant),
      entityId: _str(p['entity_id']) ?? _str(p['task_id']) ?? _str(p['report_id']),
      readAt: r.readAt?.toUtc(),
      ackedAt: r.ackedAt?.toUtc(),
      expiresAt: r.expiresAt?.toUtc() ?? _date(p['expires_at']),
      isSimulated: r.isSimulated,
    );
  }

  static String _wire(String v) => v == _unknownWire ? 'unknown' : v;

  static Map<String, Object?> _decode(String json) {
    try {
      final d = jsonDecode(json);
      return d is Map ? d.cast<String, Object?>() : const {};
    } on FormatException {
      return const {};
    }
  }

  static String? _str(Object? v) => v?.toString();

  static bool _bool(Object? v) => v == true || v == 'true';

  static DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v)?.toUtc() : null;
}
