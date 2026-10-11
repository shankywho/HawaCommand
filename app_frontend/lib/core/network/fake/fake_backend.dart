// In-process stand-in for the HawaCommand API, built from assets/fixtures.
//
// Pure Dart on purpose (only `dart:` imports): the same engine serves fake mode inside the app
// and the HTTP + WebSocket mock server in tool/mock_server, so both behave identically.
// Every fixture date is rebased from 2026-11-13 to today (IST) when it is loaded.
import 'dart:async';
import 'dart:convert';
import 'dart:math';

/// Reads a fixture by relative path, e.g. `api/tasks_mine_driver.json`.
typedef FixtureLoader = Future<String> Function(String path);

/// An HTTP error with a problem+json body (API.md §1.4).
class FakeHttpException implements Exception {
  FakeHttpException(
    this.status,
    this.code, {
    this.title,
    this.detail,
    this.extra = const {},
    this.retryAfter,
  });

  final int status;
  final String code;
  final String? title;
  final String? detail;
  final Map<String, Object?> extra;
  final int? retryAfter;

  Map<String, Object?> toProblem({String? requestId, String? instance}) => {
    'type': 'urn:hawa:problem:$code',
    'title': title ?? code,
    'status': status,
    'detail': detail,
    'instance': instance,
    'code': code,
    'request_id': requestId,
    'errors': <Object?>[],
    ...extra,
  };

  @override
  String toString() => 'FakeHttpException($status $code)';
}

/// The fake network is down (Dev tools "Go offline").
class FakeNetworkException implements Exception {
  @override
  String toString() => 'FakeNetworkException';
}

class FakeSession {
  FakeSession({
    required this.userId,
    required this.me,
    required this.role,
    required this.access,
    required this.refresh,
    required this.lang,
    required this.phone,
  });

  final String userId;
  final Map<String, Object?> me;
  String role;
  String access;
  String refresh;
  String lang;
  final String phone;

  List<String> get roles => [
    for (final r in (me['roles'] as List? ?? [me['role']])) r.toString(),
  ];
}

class FakeBackend {
  FakeBackend({
    required this._load,
    DateTime Function()? now,
    this.latency = const Duration(milliseconds: 180),
    this.strictAuth = false,
  }) : _now = now ?? (() => DateTime.now().toUtc());

  static const fixtureBaseDate = '2026-11-13';
  static const otpCode = '123456';

  /// Demo phone numbers → `/v1/me` fixture. Any other number becomes a new citizen.
  static const phoneFixtures = {
    '+919810012345': 'me_driver.json',
    '+919810022222': 'me_inspector.json',
    '+919810033333': 'me_school.json',
    '+919810044444': 'me_site_manager.json',
    '+919810055555': 'me_multi_role.json',
    '+919810066666': 'me_officer.json',
  };

  final FixtureLoader _load;
  final DateTime Function() _now;
  final Duration latency;

  /// Mock server: unknown or expired tokens get 401. In-app: the last session is assumed.
  final bool strictAuth;

  /// Base URL the presign response points uploads at (mock server sets an HTTP URL).
  String uploadBaseUrl = 'fake-s3://hawa-demo-media';

  bool offline = false;

  final _rand = Random();
  final _events = StreamController<Map<String, Object?>>.broadcast();
  final _changes = StreamController<void>.broadcast();
  final _sessions = <String, FakeSession>{};
  final _refreshTokens = <String, FakeSession>{};
  final _otpAttempts = <String, int>{};
  final _idempotency = <String, Map<String, Object?>>{};
  final _uploadedKeys = <String>{};
  final _timers = <Timer>[];
  FakeSession? _lastSession;
  int _seq = 0;
  bool _loaded = false;
  int _dayOffset = 0;
  String _today = fixtureBaseDate;

  // Mutable world state (rebased JSON).
  late Map<String, Object?> _driverDay;
  late Map<String, Object?> _inspectorDay;
  late List<Map<String, Object?>> _inspections;
  final _inspectionDetails = <String, Map<String, Object?>>{};
  late List<Map<String, Object?>> _alerts;
  late List<Map<String, Object?>> _reports;
  final _reportDetails = <String, Map<String, Object?>>{};
  late Map<String, Object?> _school;
  late Map<String, Object?> _safeToday;
  late Map<String, Object?> _safeTomorrow;
  late Map<String, Object?> _indoorOutdoor;
  late Map<String, Object?> _forecast;
  late Map<String, Object?> _grap;
  late Map<String, Object?> _openAir;
  late Map<String, Object?> _site;
  late Map<String, Object?> _subscription;
  final _meFixtures = <String, Map<String, Object?>>{};

  /// WS envelopes for every session (filter by [eventsFor]).
  Stream<Map<String, Object?>> get events => _events.stream;

  /// Fires after every state change (the app persists fake state on it).
  Stream<void> get changes => _changes.stream;

  String get today => _today;

  // ------------------------------------------------------------------ loading and rebasing

  Future<void> ensureLoaded() async {
    final todayIst = _istDate(_now());
    if (_loaded && todayIst == _today) return;
    _today = todayIst;
    _dayOffset = _daysBetween(fixtureBaseDate, _today);
    _driverDay = await _fixture('api/tasks_mine_driver.json');
    _inspectorDay = await _fixture('api/tasks_mine_inspector.json');
    _inspections = _list((await _fixture('api/inspections_assigned.json'))['items']);
    for (final name in ['api/inspection_detail.json', 'api/inspection_detail_site.json']) {
      final d = await _fixture(name);
      _inspectionDetails[d['id']! as String] = d;
    }
    _alerts = _list((await _fixture('api/alerts.json'))['items']);
    _reports = _list((await _fixture('api/reports_mine.json'))['items']);
    final closed = await _fixture('api/report_detail_closed.json');
    _reportDetails[closed['id']! as String] = closed;
    _school = await _fixture('api/school_me.json');
    _safeToday = await _fixture('api/safe_window_2026-11-13.json');
    _safeTomorrow = await _fixture('api/safe_window_2026-11-14.json');
    _indoorOutdoor = await _fixture('api/indoor_outdoor.json');
    _forecast = await _fixture('api/forecast_cell.json');
    _grap = await _fixture('api/grap_outlook.json');
    _openAir = await _fixture('api/open_air_bbox.json');
    _site = await _fixture('api/sites_me.json');
    _subscription = await _fixture('api/alert_subscription.json');
    for (final f in {...phoneFixtures.values, 'me_citizen.json'}) {
      _meFixtures[f] = await _fixture('api/$f');
    }
    _loaded = true;
  }

  Future<Map<String, Object?>> _fixture(String path) async {
    final decoded = jsonDecode(await _load(path));
    return _rebase(decoded)! as Map<String, Object?>;
  }

  static final _isoDateTime = RegExp(r'^(\d{4}-\d{2}-\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d+)?Z$');
  static final _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final _dateParam = RegExp(r'date=(\d{4}-\d{2}-\d{2})');

  Object? _rebase(Object? v) {
    if (v is Map) {
      return <String, Object?>{for (final e in v.entries) e.key.toString(): _rebase(e.value)};
    }
    if (v is List) return [for (final e in v) _rebase(e)];
    if (v is String) return _rebaseString(v);
    return v;
  }

  String _rebaseString(String s) {
    if (_dayOffset == 0) return s;
    if (_isoDateTime.hasMatch(s)) return _iso(DateTime.parse(s).add(Duration(days: _dayOffset)));
    if (_isoDate.hasMatch(s)) return _shiftDate(s, _dayOffset);
    if (s.contains('date=')) {
      return s.replaceAllMapped(_dateParam, (m) => 'date=${_shiftDate(m[1]!, _dayOffset)}');
    }
    return s;
  }

  // ------------------------------------------------------------------ persistence (in-app fake mode)

  Map<String, Object?> exportState() => {
    'today': _today,
    'driver_day': _driverDay,
    'inspector_day': _inspectorDay,
    'inspections': _inspections,
    'inspection_details': _inspectionDetails,
    'alerts': _alerts,
    'reports': _reports,
    'report_details': _reportDetails,
    'subscription': _subscription,
    'uploaded': _uploadedKeys.toList(),
    'idempotency': _idempotency,
  };

  /// Restores a snapshot from the same IST day; older snapshots are ignored (fresh fixtures).
  Future<void> importState(Map<String, Object?> state) async {
    await ensureLoaded();
    if (state['today'] != _today) return;
    _driverDay = _map(state['driver_day']);
    _inspectorDay = _map(state['inspector_day']);
    _inspections = _list(state['inspections']);
    _inspectionDetails
      ..clear()
      ..addAll(_map(state['inspection_details']).map((k, v) => MapEntry(k, _map(v))));
    _alerts = _list(state['alerts']);
    _reports = _list(state['reports']);
    _reportDetails
      ..clear()
      ..addAll(_map(state['report_details']).map((k, v) => MapEntry(k, _map(v))));
    _subscription = _map(state['subscription']);
    _uploadedKeys
      ..clear()
      ..addAll([for (final k in (state['uploaded'] as List? ?? const [])) k.toString()]);
    _idempotency
      ..clear()
      ..addAll(_map(state['idempotency']).map((k, v) => MapEntry(k, _map(v))));
    // Reports still in progress continue on a short timer.
    for (final r in _reports) {
      if (!const {'closed', 'rejected'}.contains(r['status'])) {
        _scheduleReportProgress(r['id']! as String);
      }
    }
  }

  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    unawaited(_events.close());
    unawaited(_changes.close());
  }

  // ------------------------------------------------------------------ auth (API.md §3)

  Future<Map<String, Object?>> otpRequest(Map<String, Object?> body) => _call(() async {
    final phone = body['phone_e164']?.toString() ?? '';
    if (!RegExp(r'^\+91[6-9]\d{9}$').hasMatch(phone)) {
      throw FakeHttpException(
        422,
        'validation_failed',
        detail: 'phone_e164 must be +91 and 10 digits',
      );
    }
    _otpAttempts[phone] = 0;
    return {'status': 'sent', 'expires_in': 300, 'resend_after': 30, 'request_id': _uuid()};
  }, auth: false);

  Future<Map<String, Object?>> otpVerify(Map<String, Object?> body) => _call(() async {
    final phone = body['phone_e164']?.toString() ?? '';
    final code = body['code']?.toString() ?? '';
    final attempts = _otpAttempts[phone];
    if (attempts == null) throw FakeHttpException(401, 'auth.otp_expired');
    if (code != otpCode) {
      final used = attempts + 1;
      _otpAttempts[phone] = used;
      if (used >= 5) {
        _otpAttempts.remove(phone);
        throw FakeHttpException(429, 'auth.otp_attempts_exceeded', retryAfter: 60);
      }
      throw FakeHttpException(401, 'auth.otp_invalid', extra: {'attempts_left': 5 - used});
    }
    _otpAttempts.remove(phone);
    final fixture = phoneFixtures[phone] ?? 'me_citizen.json';
    final me = Map<String, Object?>.of(_meFixtures[fixture]!);
    if (fixture == 'me_citizen.json') {
      // A new citizen per unknown number (API.md §3: unknown phones become citizens).
      me['id'] = _uuidFromSeed(phone);
      me['phone_e164'] = phone;
    }
    final session = FakeSession(
      userId: me['id']! as String,
      me: me,
      role: me['role']! as String,
      access: '',
      refresh: '',
      lang: body['lang']?.toString() ?? me['lang']?.toString() ?? 'hi',
      phone: phone,
    );
    return _issueTokens(session);
  }, auth: false);

  Future<Map<String, Object?>> refresh(Map<String, Object?> body) => _call(() async {
    final token = body['refresh_token']?.toString();
    final session = _refreshTokens.remove(token);
    if (session == null) throw FakeHttpException(401, 'auth.refresh_invalid');
    _sessions.remove(session.access);
    return _issueTokens(session);
  }, auth: false);

  Future<void> logout({String? token}) => _call(() async {
    final s = _session(token);
    _sessions.remove(s.access);
    _refreshTokens.remove(s.refresh);
    if (identical(_lastSession, s)) _lastSession = null;
    return <String, Object?>{};
  });

  Future<Map<String, Object?>> switchRole(Map<String, Object?> body, {String? token}) =>
      _call(() async {
        final s = _session(token);
        final role = body['role']?.toString();
        if (role == null || !s.roles.contains(role)) throw FakeHttpException(403, 'forbidden');
        s.role = role;
        _sessions.remove(s.access);
        _refreshTokens.remove(s.refresh);
        return _issueTokens(s);
      });

  Map<String, Object?> _issueTokens(FakeSession s) {
    final now = _now();
    final exp = now.add(const Duration(minutes: 15)).millisecondsSinceEpoch ~/ 1000;
    String b64(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
    s
      ..access =
          '${b64({'alg': 'none', 'typ': 'JWT'})}.${b64({'sub': s.userId, 'role': s.role, 'roles': s.roles, 'exp': exp, 'iat': now.millisecondsSinceEpoch ~/ 1000, 'jti': _uuid()})}.fake'
      ..refresh = 'rt_${_hex(24)}';
    _sessions[s.access] = s;
    _refreshTokens[s.refresh] = s;
    _lastSession = s;
    return {
      'access_token': s.access,
      'token_type': 'Bearer',
      'expires_in': 900,
      'refresh_token': s.refresh,
      'refresh_expires_in': 2592000,
      'user': {
        'id': s.userId,
        'role': s.role,
        'roles': s.roles,
        'display_name': s.me['display_name'],
        'lang': s.lang,
        'wards': [for (final w in (s.me['wards'] as List? ?? const [])) (w as Map)['ward_id']],
        'asset_ids': s.me['asset_ids'] ?? <Object?>[],
        'school_id': (s.me['school'] as Map?)?['school_id'],
        'site_id': (s.me['site'] as Map?)?['site_id'],
        'is_simulated': true,
      },
    };
  }

  FakeSession _session(String? token) {
    final s = token == null ? (strictAuth ? null : _lastSession) : _sessions[token];
    if (s == null) {
      if (!strictAuth && _lastSession != null) return _lastSession!;
      throw FakeHttpException(401, token == null ? 'unauthenticated' : 'auth.token_invalid');
    }
    final exp = _jwtExp(s.access);
    if (strictAuth && exp != null && exp.isBefore(_now())) {
      throw FakeHttpException(401, 'auth.token_expired');
    }
    return s;
  }

  /// Rebuilds a session from a still-valid token after an app restart (in-app fake mode).
  void adoptSession({
    required String access,
    required String refresh,
    required Map<String, Object?> me,
    required String role,
    required String lang,
  }) {
    if (_sessions.containsKey(access)) return;
    final s = FakeSession(
      userId: me['id']?.toString() ?? '',
      me: me,
      role: role,
      access: access,
      refresh: refresh,
      lang: lang,
      phone: me['phone_e164']?.toString() ?? '',
    );
    _sessions[access] = s;
    _refreshTokens[refresh] = s;
    _lastSession = s;
  }

  // ------------------------------------------------------------------ me

  Future<Map<String, Object?>> me({String? token}) => _call(() async {
    final s = _session(token);
    return {...s.me, 'role': s.role, 'roles': s.roles, 'lang': s.lang};
  });

  Future<Map<String, Object?>> patchMe(Map<String, Object?> body, {String? token, String? key}) =>
      _mutate(key, () async {
        final s = _session(token);
        if (body['lang'] is String) s.lang = body['lang']! as String;
        if (body['notification_prefs'] is Map) {
          s.me['notification_prefs'] = body['notification_prefs'];
        }
        return {...s.me, 'role': s.role, 'roles': s.roles, 'lang': s.lang};
      });

  Future<Map<String, Object?>> putPushToken(Map<String, Object?> body, {String? token}) =>
      _call(() async {
        _session(token);
        return {
          'id': _uuid(),
          'platform': body['platform'] ?? 'android',
          'last_seen_at': _iso(_now()),
        };
      });

  Future<Map<String, Object?>> getAlertSubscription({String? token}) => _call(() async {
    _session(token);
    return _subscription;
  });

  Future<Map<String, Object?>> putAlertSubscription(
    Map<String, Object?> body, {
    String? token,
    String? key,
  }) => _mutate(key, () async {
    _session(token);
    return _subscription = Map.of(body);
  });

  // ------------------------------------------------------------------ tasks (API.md §7)

  Future<Map<String, Object?>> tasksMine({String? date, String? token}) => _call(() async {
    final s = _session(token);
    final day = _dayFor(s.role);
    final asked = date ?? _today;
    if (day == null || asked != _today) {
      return {'date': asked, 'role': s.role, 'items': <Object?>[], 'server_time': _iso(_now())};
    }
    return {...day, 'server_time': _iso(_now())};
  });

  Future<Map<String, Object?>> taskGet(String id, {String? token}) => _call(() async {
    final s = _session(token);
    return _findTask(s.role, id);
  });

  Future<Map<String, Object?>> taskAck(
    String id,
    Map<String, Object?> body, {
    String? token,
    String? key,
  }) => _mutate(key, () async {
    final s = _session(token);
    final t = _findTask(s.role, id);
    final status = t['status'];
    if (status == 'dispatched') {
      _setStatus(t, 'acknowledged', s.role);
    } else if (status != 'acknowledged') {
      _guardTerminal(t);
      throw FakeHttpException(409, 'transition_already_past', extra: {'current_status': status});
    }
    return {'task_id': id, 'status': 'acknowledged', 'acknowledged_at': body['at'] ?? _iso(_now())};
  });

  Future<Map<String, Object?>> taskStatus(
    String id,
    Map<String, Object?> body, {
    String? token,
    String? key,
  }) => _mutate(key, () async {
    final s = _session(token);
    final t = _findTask(s.role, id);
    final to = body['status']?.toString();
    final from = t['status']?.toString();
    if (from == 'cancelled') throw FakeHttpException(409, 'task_cancelled');
    if (_terminal.contains(from) && to != from) {
      if (const {'done', 'verifying', 'verified', 'inconclusive'}.contains(from)) {
        throw FakeHttpException(
          409,
          'task_already_done',
          extra: {'completion_source': t['completion_source']},
        );
      }
      throw FakeHttpException(409, 'task.invalid_transition', extra: {'current_status': from});
    }
    switch (to) {
      case 'en_route':
        if (from == 'en_route') throw FakeHttpException(409, 'already_in_state');
        if (!const {'dispatched', 'acknowledged'}.contains(from)) {
          throw FakeHttpException(409, 'transition_already_past', extra: {'current_status': from});
        }
        _setStatus(t, 'en_route', s.role);
      case 'in_progress':
        if (from == 'in_progress') throw FakeHttpException(409, 'already_in_state');
        if (!const {'acknowledged', 'en_route'}.contains(from)) {
          throw FakeHttpException(409, 'task.invalid_transition', extra: {'current_status': from});
        }
        _setStatus(t, 'in_progress', s.role);
      case 'done':
        if (!const {'acknowledged', 'en_route', 'in_progress'}.contains(from)) {
          throw FakeHttpException(409, 'task.invalid_transition', extra: {'current_status': from});
        }
        t
          ..['completion_source'] = 'manual'
          ..['intervention_id'] = _uuid()
          ..['litres'] = body['litres'];
        _setStatus(t, 'done', s.role, source: 'manual');
        return {
          'task_id': id,
          'status': 'done',
          'status_source': 'manual',
          'intervention_id': t['intervention_id'],
          'evidence_level': 'low',
          'verify_after': _iso(_now().add(const Duration(hours: 2))),
        };
      case 'skipped':
        if (body['reason'] == null) {
          throw FakeHttpException(422, 'validation_failed', detail: 'reason required');
        }
        t['skip_reason'] = body['reason'];
        _setStatus(t, 'skipped', s.role);
      default:
        throw FakeHttpException(
          422,
          'validation_failed',
          detail: 'status $to not allowed from the app',
        );
    }
    return {'task_id': id, 'status': t['status']};
  });

  // ------------------------------------------------------------------ shifts (proposed)

  Future<Map<String, Object?>> shiftAction(
    String shiftId,
    String action,
    Map<String, Object?> body, {
    String? token,
    String? key,
  }) => _mutate(key, () async {
    final s = _session(token);
    final day = _dayFor(s.role);
    final shift = day == null ? null : day['shift'] as Map?;
    if (shift == null || shift['id'] != shiftId) throw FakeHttpException(404, 'not_found');
    final at = body['at']?.toString() ?? _iso(_now());
    if (action == 'start') {
      shift
        ..['status'] = 'active'
        ..['started_at'] = at;
    } else {
      shift
        ..['status'] = 'ended'
        ..['ended_at'] = at;
    }
    _changed();
    return {
      'shift_id': shiftId,
      'status': shift['status'],
      'started_at': shift['started_at'],
      'ended_at': shift['ended_at'],
    };
  });

  Future<Map<String, Object?>> shiftLocations(
    String shiftId,
    Map<String, Object?> body, {
    String? token,
    String? key,
  }) => _mutate(key, () async {
    _session(token);
    return {'accepted': (body['pings'] as List? ?? const []).length};
  });

  // ------------------------------------------------------------------ inspections (API.md §13)

  Future<Map<String, Object?>> inspectionsList({String? status, String? token}) => _call(() async {
    _session(token);
    final open = status == null || status == 'assigned';
    final items = _inspections
        .where((i) => !open || const {'open', 'assigned', 'on_site'}.contains(i['status']))
        .toList();
    return {'items': items, 'next_cursor': null};
  });

  Future<Map<String, Object?>> inspectionGet(String id, {String? token}) => _call(() async {
    _session(token);
    final detail = _inspectionDetails[id];
    if (detail != null) return detail;
    final item = _inspections.where((i) => i['id'] == id).firstOrNull;
    if (item == null) throw FakeHttpException(404, 'not_found');
    return {
      'id': id,
      'status': item['status'],
      'task_id': item['task_id'],
      'report_id': item['report_id'],
      'origin': item['origin'],
      'priority': item['priority'],
      'cause_label': item['cause_label'] ?? 'unknown',
      'cause_conf': item['cause_conf'] ?? 0.5,
      'place_name': item['place_name'],
      'suspect_pin': item['target'],
      'photos': <Object?>[],
      'reporter': null,
      'created_at': item['created_at'],
      'is_simulated': true,
    };
  });

  Future<Map<String, Object?>> inspectionClose(
    String id,
    Map<String, Object?> body, {
    String? token,
    String? key,
  }) => _mutate(key, () async {
    final s = _session(token);
    final item = _inspections.where((i) => i['id'] == id).firstOrNull;
    if (item == null) throw FakeHttpException(404, 'not_found');
    for (final k in (body['evidence_keys'] as List? ?? const [])) {
      if (!_uploadedKeys.contains(k)) {
        throw FakeHttpException(422, 'upload.not_found', detail: 'unknown key $k');
      }
    }
    final outcome = body['outcome']?.toString() ?? 'closed_confirmed';
    if (const {
      'closed_confirmed',
      'closed_not_found',
      'closed_unreachable',
    }.contains(item['status'])) {
      // Proposed (app PLAN §11 #2): late evidence is attached, not discarded.
      return {'id': id, 'status': item['status'], 'closed_at': item['closed_at'], 'applied': false};
    }
    final closedAt = body['closed_at']?.toString() ?? _iso(_now());
    item
      ..['status'] = outcome
      ..['closed_at'] = closedAt;
    _inspectionDetails[id]?['status'] = outcome;
    final taskId = item['task_id'];
    if (taskId is String) {
      final t = _taskIn(_inspectorDay, taskId);
      if (t != null && !_terminal.contains(t['status'])) _setStatus(t, 'done', 'inspector');
    }
    final reportId = item['report_id'];
    if (reportId is String) _closeReport(reportId, outcome, closedAt);
    if (s.role != 'inspector') _changed();
    return {'id': id, 'status': outcome, 'closed_at': closedAt, 'applied': true};
  });

  Future<Map<String, Object?>> inspectionOnSite(
    String id,
    Map<String, Object?> body, {
    String? token,
    String? key,
  }) => _mutate(key, () async {
    _session(token);
    final item = _inspections.where((i) => i['id'] == id).firstOrNull;
    if (item == null) throw FakeHttpException(404, 'not_found');
    if (item['status'] == 'assigned' || item['status'] == 'open') item['status'] = 'on_site';
    _changed();
    return {'id': id, 'status': item['status']};
  });

  // ------------------------------------------------------------------ alerts (API.md §10)

  Future<Map<String, Object?>> alertsList({String? token}) => _call(() async {
    final s = _session(token);
    return {
      'items': [for (final a in _alertsFor(s)) _alertOut(a, s.lang)],
      'next_cursor': null,
    };
  });

  Future<Map<String, Object?>> alertGet(String id, {String? token}) => _call(() async {
    final s = _session(token);
    final a = _alertsFor(s).where((a) => a['id'] == id).firstOrNull;
    if (a == null) throw FakeHttpException(404, 'not_found');
    return _alertOut(a, s.lang);
  });

  Future<Map<String, Object?>> alertAck(
    String id,
    Map<String, Object?> body, {
    String? token,
    String? key,
  }) => _mutate(key, () async {
    final s = _session(token);
    final a = _alertsFor(s).where((a) => a['id'] == id).firstOrNull;
    if (a == null) throw FakeHttpException(404, 'not_found');
    a['acked_at'] ??= body['at'] ?? _iso(_now());
    a['read_at'] ??= a['acked_at'];
    _changed();
    return {'id': id, 'acked_at': a['acked_at']};
  });

  List<Map<String, Object?>> _alertsFor(FakeSession s) {
    final audience = s.role;
    final list = _alerts.where((a) => a['audience'] == audience).toList()
      ..sort((a, b) => (b['created_at']! as String).compareTo(a['created_at']! as String));
    return list;
  }

  Map<String, Object?> _alertOut(Map<String, Object?> a, String lang) {
    final hi = lang == 'hi';
    final out = Map<String, Object?>.of(a)
      ..remove('title_hi')
      ..remove('body_hi')
      ..['lang'] = hi ? 'hi' : 'en'
      ..['title'] = hi ? (a['title_hi'] ?? a['title']) : a['title']
      ..['body'] = hi ? (a['body_hi'] ?? a['body']) : a['body'];
    return out;
  }

  // ------------------------------------------------------------------ schools, forecast, GRAP

  Future<Map<String, Object?>> schoolsMe({String? token}) => _call(() async {
    final s = _session(token);
    if (s.role != 'school') throw FakeHttpException(403, 'forbidden');
    return _school;
  });

  Future<Map<String, Object?>> safeWindow(String schoolId, {String? date, String? token}) =>
      _call(() async {
        _session(token);
        if (schoolId != _school['school_id']) throw FakeHttpException(404, 'not_found');
        final asked = date ?? _today;
        if (asked == _today) return _safeToday;
        if (asked == _shiftDate(_today, 1)) return _safeTomorrow;
        throw FakeHttpException(404, 'not_found', detail: 'No safe-window issue for $asked');
      });

  Future<Map<String, Object?>> indoorOutdoor(String schoolId, {String? token}) => _call(() async {
    _session(token);
    if (schoolId != _school['school_id']) throw FakeHttpException(404, 'not_found');
    return _indoorOutdoor;
  });

  Future<Map<String, Object?>> forecast(String cellId, {String? token}) => _call(() async {
    _session(token);
    return {..._forecast, 'requested_cell_id': cellId};
  });

  Future<Map<String, Object?>> grapOutlook(String ward, {String? token}) => _call(() async {
    _session(token);
    return {..._grap, 'ward_id': ward};
  });

  /// Open data is public. The 1 km grid is re-centred on the requested box, so the demo works
  /// wherever the phone is (place names are dropped when that happens: they would be wrong).
  Future<Map<String, Object?>> openAir({String? bbox}) => _call(() async {
    final parts = bbox?.split(',').map(double.tryParse).toList();
    if (parts == null || parts.length != 4 || parts.any((p) => p == null)) return _openAir;
    final cLon = (parts[0]! + parts[2]!) / 2;
    final cLat = (parts[1]! + parts[3]!) / 2;
    const fLon = 77.19;
    const fLat = 28.644;
    final dLon = cLon - fLon;
    final dLat = cLat - fLat;
    if (dLon.abs() < 0.03 && dLat.abs() < 0.03) return _openAir;
    final features = [
      for (final f in _openAir['features']! as List)
        {
          ...(f as Map).cast<String, Object?>(),
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              for (final ring in ((f['geometry'] as Map)['coordinates'] as List))
                [
                  for (final c in ring as List)
                    [_r6(((c as List)[0] as num) + dLon), _r6((c[1] as num) + dLat)],
                ],
            ],
          },
          'properties': {...((f['properties'] as Map).cast<String, Object?>()), 'place_name': null},
        },
    ];
    return {..._openAir, 'features': features};
  }, auth: false);

  // ------------------------------------------------------------------ uploads + reports

  Future<Map<String, Object?>> presign(Map<String, Object?> body, {String? token}) =>
      _call(() async {
        _session(token);
        final length = (body['content_length'] as num?)?.toInt() ?? 0;
        if (length > 8 * 1024 * 1024) throw FakeHttpException(413, 'upload.too_large');
        final purpose = body['purpose']?.toString() ?? 'report_photo';
        final d = _today.split('-');
        final key = 'uploads/$purpose/${d[0]}/${d[1]}/${d[2]}/${_uuid()}.jpg';
        return {
          'key': key,
          'url': uploadBaseUrl,
          'method': 'POST',
          'fields': {
            'key': key,
            'Content-Type': 'image/jpeg',
            'policy': 'fake-policy',
            'x-amz-signature': _hex(16),
          },
          'expires_at': _iso(_now().add(const Duration(minutes: 5))),
          'max_bytes': 8388608,
        };
      });

  /// The presigned upload target (fake S3).
  void markUploaded(String key) {
    _uploadedKeys.add(key);
    _changed();
  }

  Future<Map<String, Object?>> reportsCreate(
    Map<String, Object?> body, {
    String? token,
    String? key,
  }) => _mutate(key, () async {
    final s = _session(token);
    final photoKey = body['photo_key']?.toString();
    if (photoKey == null) throw FakeHttpException(422, 'report.photo_required');
    if (!_uploadedKeys.contains(photoKey)) throw FakeHttpException(422, 'upload.not_found');
    final clientId = body['client_report_id']?.toString();
    final existing = _reports.where((r) => r['client_report_id'] == clientId).firstOrNull;
    if (existing != null) {
      return {
        'report_id': existing['id'],
        'client_report_id': clientId,
        'status': existing['status'],
        'ward_id': 'ward-084',
      };
    }
    final id = _uuid();
    final now = _iso(_now());
    final location = body['location'];
    final item = <String, Object?>{
      'id': id,
      'client_report_id': clientId,
      'status': 'submitted',
      'created_at': now,
      'ward_id': 'ward-084',
      'note': body['note'],
      'thumbnail_url': 'asset://assets/images/fixtures/report_burning.jpg',
      'place_name': {'en': 'Near you', 'hi': 'आपके पास'},
      'verification_label': null,
      'inspection_status': null,
      'outcome_text': null,
      'outcome_text_hi': null,
      'closed_at': null,
      'source': 'app',
      'is_simulated': true,
    };
    _reports.insert(0, item);
    _reportDetails[id] = {
      'id': id,
      'client_report_id': clientId,
      'source': 'app',
      'status': 'submitted',
      'location': location,
      'accuracy_m': body['accuracy_m'],
      'ward_id': 'ward-084',
      'cell_id': 'g500-041-077',
      'place_name': item['place_name'],
      'note': body['note'],
      'lang': body['lang'] ?? s.lang,
      'category': body['category'],
      'captured_at': body['captured_at'],
      'created_at': now,
      'photo_url': 'asset://assets/images/fixtures/report_burning.jpg',
      'verification': {'verified': false},
      'inspection': null,
      'outcome': null,
      'outcome_text': null,
      'outcome_text_hi': null,
      'rejection_reason': null,
      'closed_at': null,
      'timeline': [
        {'status': 'submitted', 'at': now},
      ],
      'is_simulated': true,
    };
    _scheduleReportProgress(id);
    return {
      'report_id': id,
      'client_report_id': clientId,
      'status': 'submitted',
      'ward_id': 'ward-084',
      'cell_id': 'g500-041-077',
    };
  });

  Future<Map<String, Object?>> reportsMine({String? token}) => _call(() async {
    _session(token);
    return {'items': _reports, 'next_cursor': null};
  });

  Future<Map<String, Object?>> reportGet(String id, {String? token}) => _call(() async {
    _session(token);
    final d = _reportDetails[id];
    if (d != null) return d;
    final item = _reports.where((r) => r['id'] == id).firstOrNull;
    if (item == null) throw FakeHttpException(404, 'not_found');
    return {
      'id': id,
      'client_report_id': item['client_report_id'],
      'source': item['source'],
      'status': item['status'],
      'location': {
        'type': 'Point',
        'coordinates': [77.1838, 28.6402],
      },
      'created_at': item['created_at'],
      'place_name': item['place_name'],
      'note': item['note'],
      'photo_url': item['thumbnail_url'],
      'timeline': [
        {'status': 'submitted', 'at': item['created_at']},
        if (item['status'] != 'submitted') {'status': item['status'], 'at': item['created_at']},
      ],
      'outcome': item['inspection_status'],
      'outcome_text': item['outcome_text'],
      'outcome_text_hi': item['outcome_text_hi'],
      'is_simulated': true,
    };
  });

  void _scheduleReportProgress(String id) {
    const steps = [
      (Duration(seconds: 4), 'verifying'),
      (Duration(seconds: 10), 'verified'),
      (Duration(seconds: 16), 'ticketed'),
      (Duration(seconds: 45), 'closed'),
    ];
    for (final (delay, status) in steps) {
      _timers.add(
        Timer(delay, () {
          final item = _reports.where((r) => r['id'] == id).firstOrNull;
          if (item == null) return;
          const order = ['submitted', 'verifying', 'verified', 'ticketed', 'closed'];
          if (order.indexOf(item['status']! as String) >= order.indexOf(status)) return;
          if (status == 'closed') {
            _closeReport(id, 'closed_confirmed', _iso(_now()));
            return;
          }
          _advanceReport(id, status);
        }),
      );
    }
  }

  void _advanceReport(String id, String status) {
    final at = _iso(_now());
    final item = _reports.where((r) => r['id'] == id).firstOrNull;
    if (item == null) return;
    item['status'] = status;
    final d = _reportDetails[id];
    if (d != null) {
      d['status'] = status;
      (d['timeline']! as List).add({'status': status, 'at': at});
      if (status == 'verified') {
        d['verification'] = {
          'verified': true,
          'label': 'burning',
          'confidence': 0.88,
          'verified_at': at,
          'model_version': 'vision@0.2.0+a1b2c3d',
        };
        item['verification_label'] = 'burning';
      }
      if (status == 'ticketed') {
        final inspectionId = _uuid();
        final pin =
            d['location'] ??
            {
              'type': 'Point',
              'coordinates': [77.1838, 28.6402],
            };
        _inspections.add({
          'id': inspectionId,
          'status': 'assigned',
          'origin': 'report',
          'priority': 2,
          'target': pin,
          'ward_id': 'ward-084',
          'report_id': id,
          'task_id': null,
          'place_name': d['place_name'],
          'cause_label': 'burning',
          'cause_conf': 0.88,
          'evidence_summary': {
            'spike_ratio': 2.6,
            'photo_label': 'burning',
            'photo_conf': 0.88,
            'fire_points': 0,
          },
          'assigned_team_asset_id': 'AST-TEAM-0003',
          'created_at': at,
          'is_simulated': true,
        });
        _inspectionDetails[inspectionId] = {
          'id': inspectionId,
          'status': 'assigned',
          'task_id': null,
          'report_id': id,
          'origin': 'report',
          'priority': 2,
          'cause_label': 'burning',
          'cause_conf': 0.88,
          'place_name': d['place_name'],
          'suspect_pin': pin,
          'suspect_radius_m': 150,
          'photos': [
            {
              'url': d['photo_url'],
              'thumb_url': d['photo_url'],
              'captured_at': d['captured_at'] ?? at,
              'expires_at': _iso(_now().add(const Duration(hours: 12))),
            },
          ],
          'reporter': {'kind': 'citizen'},
          'created_at': at,
          'reported_at': d['created_at'],
          'is_simulated': true,
        };
        d['inspection'] = {'id': inspectionId, 'status': 'assigned'};
        _pushAlert(
          audience: 'inspector',
          kind: 'inspection_target',
          title: 'New inspection target',
          titleHi: 'नया निरीक्षण लक्ष्य',
          body: 'Likely burning near the reported spot. Confidence high.',
          bodyHi: 'रिपोर्ट की जगह के पास संभावित खुले में जलाना। भरोसा उच्च।',
          deepLink: 'hawa://inspections/$inspectionId',
        );
      }
    }
    if (status == 'verified') {
      _pushAlert(
        audience: 'citizen',
        kind: 'report_outcome',
        title: 'Your report: Confirmed by our system',
        titleHi: 'आपकी रिपोर्ट: सिस्टम ने पुष्टि की',
        body: 'The photo shows open burning. An inspector will be sent. Thank you for reporting.',
        bodyHi:
            'फ़ोटो में खुले में जलाना दिख रहा है। निरीक्षक भेजा जाएगा। रिपोर्ट करने के लिए धन्यवाद।',
        deepLink: 'hawa://reports/$id',
        reportId: id,
      );
    }
    _changed();
  }

  void _closeReport(String reportId, String outcome, String at) {
    const texts = {
      'closed_confirmed': (
        'An inspector found and put out the fire. Thank you for reporting.',
        'निरीक्षक ने आग ढूंढकर बुझा दी। रिपोर्ट करने के लिए धन्यवाद।',
      ),
      'closed_not_found': (
        'The inspector found nothing at the spot.',
        'निरीक्षक को मौके पर कुछ नहीं मिला।',
      ),
      'closed_unreachable': (
        'The inspector could not reach the spot.',
        'निरीक्षक मौके तक नहीं पहुँच सके।',
      ),
    };
    final (en, hi) = texts[outcome] ?? texts['closed_confirmed']!;
    final item = _reports.where((r) => r['id'] == reportId).firstOrNull;
    if (item != null) {
      item
        ..['status'] = 'closed'
        ..['inspection_status'] = outcome
        ..['outcome_text'] = en
        ..['outcome_text_hi'] = hi
        ..['closed_at'] = at;
    }
    final d = _reportDetails[reportId];
    if (d != null) {
      final timeline = d['timeline']! as List;
      for (final st in ['verifying', 'verified', 'ticketed']) {
        if (!timeline.any((e) => (e as Map)['status'] == st)) {
          timeline.add({'status': st, 'at': at});
        }
      }
      timeline.add({'status': 'closed', 'at': at});
      d
        ..['status'] = 'closed'
        ..['outcome'] = outcome
        ..['outcome_text'] = en
        ..['outcome_text_hi'] = hi
        ..['closed_at'] = at;
      final insp = d['inspection'];
      if (insp is Map) insp['status'] = outcome;
    }
    _pushAlert(
      audience: 'citizen',
      kind: 'report_outcome',
      title: 'Your report: Closed',
      titleHi: 'आपकी रिपोर्ट: बंद',
      body: en,
      bodyHi: hi,
      deepLink: 'hawa://reports/$reportId',
      reportId: reportId,
    );
    _changed();
  }

  // ------------------------------------------------------------------ sites

  Future<Map<String, Object?>> sitesMe({String? token}) => _call(() async {
    final s = _session(token);
    if (s.role != 'site_manager') throw FakeHttpException(403, 'forbidden');
    return _site;
  });

  // ------------------------------------------------------------------ dev simulations (PLAN §6)

  /// HawaTag spray on the next open driver stop: `task.in_progress`, then `task.done`
  /// (source hawatag) [after] later. Returns false when nothing is left or the tag is offline.
  bool simulateSpray({Duration after = const Duration(seconds: 3)}) {
    final asset = _driverDay['asset'] as Map?;
    if (asset?['tag_status'] == 'offline') return false;
    final next = _items(_driverDay).where((t) => !_terminal.contains(t['status'])).firstOrNull;
    if (next == null) return false;
    _setStatus(next, 'in_progress', 'driver');
    _timers.add(
      Timer(after, () {
        if (next['status'] != 'in_progress') return;
        final target = (next['target_litres'] as num?)?.toDouble() ?? 500;
        next
          ..['completion_source'] = 'hawatag'
          ..['litres'] = (target * (0.96 + _rand.nextDouble() * 0.08)).roundToDouble()
          ..['intervention_id'] = _uuid();
        _setStatus(next, 'done', 'driver', source: 'hawatag');
        final remaining = _items(
          _driverDay,
        ).where((t) => !_terminal.contains(t['status'])).firstOrNull;
        _pushAlert(
          audience: 'driver',
          kind: 'task_done_auto',
          title: 'Stop ${next['sequence']} done',
          titleHi: 'स्टॉप ${next['sequence']} पूरा',
          body:
              'HawaTag recorded ${(next['litres']! as num).round()} L sprayed.${remaining == null ? '' : ' Next: ${(remaining['place_name']! as Map)['en']}.'}',
          bodyHi:
              'HawaTag ने ${(next['litres']! as num).round()} लीटर छिड़काव दर्ज किया।${remaining == null ? '' : ' अगला: ${(remaining['place_name']! as Map)['hi'] ?? (remaining['place_name']! as Map)['en']}।'}',
          deepLink: 'hawa://tasks/${next['id']}',
          taskId: next['id'] as String?,
          silentForWs: true,
        );
      }),
    );
    return true;
  }

  /// Verification of the latest done stop: `task.verifying`, then `task.verified` with impact.
  bool simulateVerify() {
    final done = _items(_driverDay).where((t) => t['status'] == 'done').toList();
    if (done.isEmpty) return false;
    final t = done.last;
    final manual = t['completion_source'] == 'manual';
    t['impact_summary'] = {
      'pollutant': 'pm10',
      'effect_pct': manual ? -9.4 : -18.2,
      'ci_low': manual ? -17.0 : -26.0,
      'ci_high': manual ? -1.8 : -9.9,
      'duration_min': 90,
      'method': manual ? 'before_after_naive' : 'synthetic_control',
      'verdict': 'effective',
      'ci_level': 0.9,
    };
    _setStatus(t, 'verified', 'driver', extra: {'impact_summary': t['impact_summary']});
    return true;
  }

  /// Re-plan: the last open stop is removed and a new stop is added (route version +1).
  bool simulateRouteChange() {
    final open = _items(_driverDay).where((t) => !_terminal.contains(t['status'])).toList();
    if (open.isEmpty) return false;
    final removed = open.last;
    _setStatus(removed, 'cancelled', 'driver');
    final items = _driverDay['items']! as List;
    final seq = items.length + 1;
    final last = items.cast<Map<String, Object?>>().last;
    final start = DateTime.parse(last['window_end']! as String).add(const Duration(minutes: 5));
    final added = <String, Object?>{
      ...Map<String, Object?>.of(last),
      'id': _uuid(),
      'status': 'dispatched',
      'sequence': seq,
      'location': {
        'type': 'Point',
        'coordinates': [77.1880, 28.6475],
      },
      'place_name': {'en': 'Faiz Rd near Jhandewalan', 'hi': 'फ़ैज़ रोड, झंडेवालान के पास'},
      'window_start': _iso(start),
      'window_end': _iso(start.add(const Duration(minutes: 30))),
      'completion_source': null,
      'litres': null,
      'impact_summary': null,
      'skip_reason': null,
      'version': 1,
      'updated_at': _iso(_now()),
    };
    items.add(added);
    final route = _driverDay['route'] as Map?;
    if (route != null) route['version'] = ((route['version'] as num?) ?? 1).toInt() + 1;
    _emit('tasks:me', 'task.updated', {
      'task_id': added['id'],
      'status': 'dispatched',
      'stop_order': seq,
      'version': 1,
    });
    _pushAlert(
      audience: 'driver',
      kind: 'route_changed',
      title: 'Your route changed',
      titleHi: 'आपका रूट बदल गया है',
      body: '1 added, 1 removed. Check the new order.',
      bodyHi: '1 जोड़ा गया, 1 हटाया गया। नया क्रम देखें।',
      deepLink: 'hawa://route?date=$_today&changed=1',
    );
    return true;
  }

  void setTagOffline({required bool offline}) {
    final asset = _driverDay['asset'] as Map?;
    if (asset == null) return;
    asset
      ..['tag_status'] = offline ? 'offline' : 'active'
      ..['tag_last_seen_at'] = _iso(_now());
    if (offline) {
      _pushAlert(
        audience: 'driver',
        kind: 'device_health',
        title: 'HawaTag offline on ${asset['label']}',
        titleHi: '${asset['label']} पर HawaTag बंद है',
        body: "Stops won't complete automatically. After spraying, tap \"Mark done manually\".",
        bodyHi: 'स्टॉप अपने-आप पूरे नहीं होंगे। छिड़काव के बाद "हाथ से पूरा दर्ज करें" दबाएँ।',
        deepLink: 'hawa://route?date=$_today',
      );
    }
    _emit('tasks:me', 'task.updated', {'asset_id': asset['id'], 'tag_status': asset['tag_status']});
    _changed();
  }

  bool get tagOffline => (_driverDay['asset'] as Map?)?['tag_status'] == 'offline';

  /// A new spike-origin target for the inspector (push `inspection_target`).
  void simulateNewTarget() {
    final id = _uuid();
    final at = _iso(_now());
    final pin = {
      'type': 'Point',
      'coordinates': [77.1951, 28.6418],
    };
    _inspections.add({
      'id': id,
      'status': 'assigned',
      'origin': 'spike',
      'priority': 1,
      'target': pin,
      'ward_id': 'ward-084',
      'place_name': {'en': 'Behind Karol Bagh market', 'hi': 'करोल बाग़ मार्केट के पीछे'},
      'cause_label': 'burning',
      'cause_conf': 0.74,
      'evidence_summary': {'spike_ratio': 3.6, 'fire_points': 0},
      'assigned_team_asset_id': 'AST-TEAM-0003',
      'created_at': at,
      'is_simulated': true,
    });
    _inspectionDetails[id] = {
      'id': id,
      'status': 'assigned',
      'origin': 'spike',
      'priority': 1,
      'cause_label': 'burning',
      'cause_conf': 0.74,
      'place_name': {'en': 'Behind Karol Bagh market', 'hi': 'करोल बाग़ मार्केट के पीछे'},
      'suspect_pin': pin,
      'suspect_radius_m': 160,
      'back_trajectory': {
        'type': 'LineString',
        'coordinates': [
          [77.2010, 28.6402],
          [77.1985, 28.6409],
          [77.1966, 28.6414],
          [77.1951, 28.6418],
        ],
      },
      'spike': {
        'pollutant': 'pm25',
        'baseline': 88,
        'peak': 317,
        'device_id': 'HPM-0142',
        'vehicle_label': 'Bus VEH-DTC-0457',
        'duration_s': 25,
        'detected_at': at,
        'series': _spikeSeries(88, 317),
      },
      'photos': <Object?>[],
      'reporter': null,
      'created_at': at,
      'is_simulated': true,
    };
    _pushAlert(
      audience: 'inspector',
      kind: 'inspection_target',
      title: 'New inspection target',
      titleHi: 'नया निरीक्षण लक्ष्य',
      body: 'Likely burning near Behind Karol Bagh market. Confidence high.',
      bodyHi: 'करोल बाग़ मार्केट के पीछे संभावित खुले में जलाना। भरोसा उच्च।',
      deepLink: 'hawa://inspections/$id',
    );
  }

  /// A test alert for the session's role (Dev tools "Send test push").
  Map<String, Object?> simulateTestAlert({String? token}) {
    final s = _session(token);
    switch (s.role) {
      case 'driver':
        _pushAlert(
          audience: 'driver',
          kind: 'route_assignment',
          title: "Today's route is ready",
          titleHi: 'आज का रूट तैयार है',
          body: '${_items(_driverDay).length} stops. Tap to start.',
          bodyHi: '${_items(_driverDay).length} स्टॉप। शुरू करने के लिए दबाएँ।',
          deepLink: 'hawa://route?date=$_today',
        );
      case 'inspector':
        simulateNewTarget();
      case 'school':
        _pushAlert(
          audience: 'school',
          kind: 'safe_window',
          title: 'Safe outdoor time tomorrow: none',
          titleHi: 'कल बाहर सुरक्षित समय: कोई नहीं',
          body: 'PM2.5 at 8 AM likely 281 µg/m³ (range 228–344). Hold assembly indoors.',
          bodyHi: 'सुबह 8 बजे PM2.5 संभावित 281 µg/m³ (दायरा 228–344)। प्रार्थना सभा अंदर करें।',
          deepLink:
              'hawa://schools/${_school['school_id']}/safe-window?date=${_shiftDate(_today, 1)}',
        );
      case 'site_manager':
        _pushAlert(
          audience: 'site_manager',
          kind: 'grap_outlook',
          title: 'GRAP Stage III likely tomorrow',
          titleHi: 'कल GRAP चरण III की संभावना',
          body: 'Probability 70 %. Plan outdoor work early.',
          bodyHi: 'संभावना 70 %। बाहर का काम पहले कर लें।',
          deepLink: 'hawa://sites/me',
        );
      default:
        _pushAlert(
          audience: 'citizen',
          kind: 'pollutant_warning',
          title: 'Smoke nearby: air very poor',
          titleHi: 'पास में धुआँ: हवा बहुत खराब',
          body: 'Wear a mask outdoors and keep windows shut until 11:00 AM.',
          bodyHi: 'सुबह 11:00 तक बाहर मास्क पहनें और खिड़कियाँ बंद रखें।',
          deepLink: 'hawa://alerts/latest',
          pollutant: 'pm25',
        );
    }
    return _alertOut(_alerts.last, s.lang);
  }

  /// WS envelopes for one session: `tasks:me` for their asset/role, `alerts:me` by audience.
  Stream<Map<String, Object?>> eventsFor({String? token}) {
    return events
        .where((e) {
          FakeSession s;
          try {
            s = _session(token);
          } on FakeHttpException {
            return false;
          }
          final data = (e['data'] as Map?) ?? const {};
          if (e['channel'] == 'alerts:me') return data['audience'] == s.role;
          return data['role'] == null || data['role'] == s.role;
        })
        .map((e) {
          final data = Map<String, Object?>.of((e['data']! as Map).cast<String, Object?>());
          if (e['channel'] == 'alerts:me') {
            final s = _session(token);
            final hi = s.lang == 'hi';
            data
              ..['title'] = hi ? (data['title_hi'] ?? data['title']) : data['title']
              ..['body'] = hi ? (data['body_hi'] ?? data['body']) : data['body']
              ..['lang'] = hi ? 'hi' : 'en';
          }
          data
            ..remove('title_hi')
            ..remove('body_hi')
            ..remove('role');
          return {...e, 'data': data};
        });
  }

  // ------------------------------------------------------------------ internals

  static const _terminal = {
    'done',
    'verifying',
    'verified',
    'inconclusive',
    'skipped',
    'cancelled',
    'missed',
    'failed',
  };

  Map<String, Object?>? _dayFor(String role) => switch (role) {
    'driver' => _driverDay,
    'inspector' => _inspectorDay,
    _ => null,
  };

  List<Map<String, Object?>> _items(Map<String, Object?> day) => [
    for (final t in (day['items'] as List? ?? const [])) (t as Map).cast<String, Object?>(),
  ];

  Map<String, Object?>? _taskIn(Map<String, Object?> day, String id) =>
      _items(day).where((t) => t['id'] == id).firstOrNull;

  Map<String, Object?> _findTask(String role, String id) {
    final day = _dayFor(role);
    final t = day == null ? null : _taskIn(day, id);
    if (t == null) throw FakeHttpException(404, 'not_found');
    return t;
  }

  void _guardTerminal(Map<String, Object?> t) {
    if (t['status'] == 'cancelled') throw FakeHttpException(409, 'task_cancelled');
  }

  void _setStatus(
    Map<String, Object?> t,
    String status,
    String role, {
    String? source,
    Map<String, Object?>? extra,
  }) {
    t
      ..['status'] = status
      ..['version'] = ((t['version'] as num?) ?? 0).toInt() + 1
      ..['updated_at'] = _iso(_now());
    _emit('tasks:me', 'task.$status', {
      'task_id': t['id'],
      'plan_id': t['plan_id'],
      'status': status,
      'stop_order': t['sequence'],
      'version': t['version'],
      'source': ?source,
      'litres': ?t['litres'],
      'intervention_id': ?t['intervention_id'],
      'is_simulated': true,
      'role': role,
      ...?extra,
    });
    _changed();
  }

  void _pushAlert({
    required String audience,
    required String kind,
    required String title,
    required String titleHi,
    required String body,
    required String bodyHi,
    required String deepLink,
    String? reportId,
    String? taskId,
    String? pollutant,
    bool silentForWs = false,
  }) {
    final id = _uuid();
    final link = deepLink == 'hawa://alerts/latest' ? 'hawa://alerts/$id' : deepLink;
    final at = _iso(_now());
    final alert = <String, Object?>{
      'id': id,
      'audience': audience,
      'kind': kind,
      'status': 'delivered',
      'channels': ['push'],
      'lang': 'en',
      'title': title,
      'body': body,
      'title_hi': titleHi,
      'body_hi': bodyHi,
      'pollutant': pollutant,
      'ward_id': 'ward-084',
      'task_id': taskId,
      'report_id': reportId,
      'deep_link': link,
      'origin': 'notifier',
      'args': <String, Object?>{},
      'created_at': at,
      'sent_at': at,
      'read_at': null,
      'acked_at': null,
      'expires_at': null,
      'is_simulated': true,
    };
    _alerts.add(alert);
    _emit('alerts:me', 'alert.requested', {
      'alert_id': id,
      'audience': audience,
      'kind': kind,
      'title': title,
      'body': body,
      'title_hi': titleHi,
      'body_hi': bodyHi,
      'deep_link': link,
      'entity_id': taskId ?? reportId,
      'is_simulated': true,
      'created_at': at,
      'push_only': silentForWs,
    });
    _changed();
  }

  void _emit(String channel, String type, Map<String, Object?> data) {
    if (_events.isClosed) return;
    _events.add({
      'channel': channel,
      'type': type,
      'event_id': _uuid(),
      'seq': ++_seq,
      'ts': _iso(_now()),
      'data': data,
    });
  }

  void _changed() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<Map<String, Object?>> _call(
    Future<Map<String, Object?>> Function() body, {
    bool auth = true,
  }) async {
    await ensureLoaded();
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (offline) throw FakeNetworkException();
    return body();
  }

  /// Mutations replay the stored response for a repeated `Idempotency-Key` (API.md §1.7).
  Future<Map<String, Object?>> _mutate(String? key, Future<Map<String, Object?>> Function() body) =>
      _call(() async {
        if (key != null && _idempotency.containsKey(key)) return _idempotency[key]!;
        final result = await body();
        if (key != null) _idempotency[key] = result;
        return result;
      });

  List<Map<String, Object?>> _spikeSeries(num base, num peak) {
    final start = _now().subtract(const Duration(minutes: 9));
    return [
      for (var k = 0; k < 31; k++)
        {
          'ts': _iso(start.add(Duration(seconds: 30 * k))),
          'value': (base + (peak - base) * exp(-pow(k - 18, 2) / 4.0) + (k.isEven ? 3 : -2))
              .roundToDouble(),
        },
    ];
  }

  static Map<String, Object?> _map(Object? v) =>
      v is Map ? v.cast<String, Object?>() : <String, Object?>{};

  static List<Map<String, Object?>> _list(Object? v) => [
    for (final e in (v as List? ?? const [])) (e as Map).cast<String, Object?>(),
  ];

  static DateTime? _jwtExp(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final map = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))) as Map;
      final exp = map['exp'];
      return exp is num
          ? DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true)
          : null;
    } on FormatException {
      return null;
    }
  }

  static String _istDate(DateTime t) {
    final w = t.toUtc().add(const Duration(hours: 5, minutes: 30));
    return '${w.year.toString().padLeft(4, '0')}-${w.month.toString().padLeft(2, '0')}-${w.day.toString().padLeft(2, '0')}';
  }

  static int _daysBetween(String a, String b) =>
      DateTime.parse('${b}T00:00:00Z').difference(DateTime.parse('${a}T00:00:00Z')).inDays;

  static String _shiftDate(String date, int days) {
    final d = DateTime.parse('${date}T00:00:00Z').add(Duration(days: days));
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static String _iso(DateTime t) {
    final u = t.toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${u.year.toString().padLeft(4, '0')}-${two(u.month)}-${two(u.day)}T${two(u.hour)}:${two(u.minute)}:${two(u.second)}Z';
  }

  static double _r6(num v) => (v * 1e6).round() / 1e6;

  String _hex(int bytes) =>
      List.generate(bytes, (_) => _rand.nextInt(256).toRadixString(16).padLeft(2, '0')).join();

  /// UUIDv7: 48-bit ms timestamp, version 7, variant 10.
  String _uuid() {
    final ms = _now().millisecondsSinceEpoch;
    final b = List<int>.generate(16, (_) => _rand.nextInt(256));
    for (var i = 0; i < 6; i++) {
      b[i] = (ms >> (8 * (5 - i))) & 0xff;
    }
    b[6] = (b[6] & 0x0f) | 0x70;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  /// Deterministic UUIDv7-shaped id for a phone (the same citizen across logins).
  String _uuidFromSeed(String seed) {
    var hash = 0;
    for (final c in seed.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    final tail = hash.toRadixString(16).padLeft(12, '0');
    return '01927f40-3333-7aaa-8bbb-${tail.substring(tail.length - 12)}';
  }
}
