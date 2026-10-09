import 'package:hawa_api/hawa_api.dart' as api;
import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/network/command_center_api.dart';
import 'package:hawa_app/core/network/interceptors/problem_json_interceptor.dart';
import 'package:hawa_app/features/alerts/data/alerts_remote_source.dart';

/// Alerts from what the backend serves today: the command center's broadcast log (`GET
/// /v1/alerts`, `{items: [{id, sentAt, audience: "School"|"Citizens", target, channel, message,
/// messageHi, …}]}`), shaped as contract `AlertItem`s. Ids are prefixed [idPrefix]: these are
/// read-only broadcasts, so acknowledging them stays on the phone (no outbox op).
class CommandCenterAlertsSource implements AlertsRemoteSource {
  CommandCenterAlertsSource(this._api, {required this.lang});

  final CommandCenterApi _api;

  /// The UI language: the broadcast carries both scripts; the item keeps one (`lang`).
  final String Function() lang;

  static const idPrefix = 'cc:';

  @override
  Future<api.AlertPage> list({String? cursor, int? limit}) async {
    try {
      final json = await _api.alerts();
      return api.AlertPage.fromJson({'items': items(json, lang: lang())});
    } on Object catch (e) {
      throw failureOf(e);
    }
  }

  @override
  Future<api.AlertItem> get(String id) async {
    final page = await list();
    return page.items.firstWhere(
      (a) => a.id == id,
      orElse: () => throw const NotFoundFailure(code: 'alert_not_found'),
    );
  }

  /// Pure mapping (unit tested).
  static List<Map<String, Object?>> items(Map<String, Object?> json, {required String lang}) {
    final simulated = json['simulated'] as bool? ?? true;
    return [
      for (final raw in (json['items'] as List<Object?>?) ?? const [])
        if (raw is Map<String, Object?> && raw['id'] != null)
          () {
            final school = (raw['audience'] as String? ?? '').toLowerCase().startsWith('school');
            final hi = lang == 'hi' && (raw['messageHi'] as String?)?.isNotEmpty == true;
            final sent = raw['sentAt'] as String? ?? DateTime.now().toUtc().toIso8601String();
            return <String, Object?>{
              'id': '$idPrefix${raw['id']}',
              'audience': school ? 'school' : 'citizen',
              'kind': school ? 'safe_window' : 'pollutant_warning',
              'status': 'delivered',
              'lang': hi ? 'hi' : 'en',
              'title':
                  raw['target'] as String? ?? (school ? 'School air alert' : 'Air quality alert'),
              'body': hi ? raw['messageHi'] : raw['message'] ?? '',
              'created_at': sent,
              'sent_at': sent,
              'is_simulated': simulated,
              'pollutant': 'pm25',
              'origin': raw['draftedBy'],
            };
          }(),
    ];
  }
}
