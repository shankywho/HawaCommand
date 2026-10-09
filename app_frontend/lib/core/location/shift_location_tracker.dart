import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hawa_app/core/location/location_service.dart';
import 'package:hawa_app/core/location/sampling_policy.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shift_location_tracker.g.dart';

/// Foreground-service position stream that exists only between Start shift and End shift
/// (ARCHITECTURE §11). It never subscribes unless [start] was called, and [stop] cancels the
/// stream (which also removes the ongoing notification).
class ShiftLocationTracker {
  ShiftLocationTracker({required this.db, Battery? battery}) : _battery = battery ?? Battery();

  final AppDatabase db;
  final Battery _battery;
  static final _log = Logger('shift-tracker');

  StreamSubscription<Position>? _sub;
  final _positions = StreamController<LocationFix>.broadcast();
  SamplingPolicy? _policy;
  Timer? _policyDebounce;
  String? _shiftLocalId;
  bool _persist = false;
  String _title = 'Shift on';
  String _body = 'Sharing location with the control room';
  GeoPoint? _nextStop;
  DateTime? _stillSince;
  LocationFix? _last;

  bool get active => _sub != null;

  LocationFix? get last => _last;

  Stream<LocationFix> get positions => _positions.stream;

  /// [persistPings]: keep pings for `location_batch` upload (inspection teams, or a driver whose
  /// HawaTag is offline). Otherwise pings stay in memory for the geofence only.
  Future<void> start({
    required String shiftLocalId,
    required String notificationTitle,
    required String notificationBody,
    bool persistPings = false,
  }) async {
    _shiftLocalId = shiftLocalId;
    _persist = persistPings;
    _title = notificationTitle;
    _body = notificationBody;
    await _resubscribe(await _choose());
  }

  /// Steers the sampling policy (closer to the next stop → finer sampling).
  void setNextStop(GeoPoint? point) {
    _nextStop = point;
    _scheduleRepolicy();
  }

  // Named flag for call-site clarity (`setPersistPings(persist: tagOffline)`).
  // ignore: use_setters_to_change_properties
  void setPersistPings({required bool persist}) => _persist = persist;

  Future<void> stop() async {
    _policyDebounce?.cancel();
    await _sub?.cancel();
    _sub = null;
    _policy = null;
    _last = null;
    _stillSince = null;
    if (_shiftLocalId != null && !_persist) await db.locationDao.purgeShift(_shiftLocalId!);
    _shiftLocalId = null;
  }

  Future<SamplingPolicy> _choose() async {
    int? level;
    var charging = false;
    try {
      level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      charging = state == BatteryState.charging || state == BatteryState.full;
    } on Object {
      level = null;
    }
    final last = _last;
    final distance = last == null || _nextStop == null
        ? null
        : Geo.distanceM(last.point, _nextStop!);
    final still = _stillSince == null
        ? Duration.zero
        : DateTime.now().toUtc().difference(_stillSince!);
    return choosePolicy(
      distanceToNextStopM: distance,
      stationaryFor: still,
      batteryLevel: level,
      charging: charging,
    );
  }

  /// The stream is re-created when the policy changes, debounced 30 s (§11.2).
  void _scheduleRepolicy() {
    if (!active) return;
    _policyDebounce?.cancel();
    _policyDebounce = Timer(const Duration(seconds: 30), () async {
      final next = await _choose();
      if (next != _policy && active) await _resubscribe(next);
    });
  }

  Future<void> _resubscribe(SamplingPolicy policy) async {
    await _sub?.cancel();
    _policy = policy;
    final settings = defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: _accuracy(policy.accuracy),
            distanceFilter: policy.distanceFilterM,
            intervalDuration: policy.interval,
            foregroundNotificationConfig: ForegroundNotificationConfig(
              notificationTitle: _title,
              notificationText: _body,
              notificationIcon: const AndroidResource(name: 'ic_stat_hawa'),
              setOngoing: true,
            ),
          )
        : LocationSettings(
            accuracy: _accuracy(policy.accuracy),
            distanceFilter: policy.distanceFilterM,
          );
    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      _onPosition,
      onError: (Object e) => _log.warning('position stream error', e),
    );
  }

  Future<void> _onPosition(Position p) async {
    final fix = LocationService.fromPosition(p);
    final speed = fix.speedMps ?? 0;
    if (speed < 1) {
      _stillSince ??= fix.at;
    } else {
      _stillSince = null;
    }
    _last = fix;
    _positions.add(fix);
    final id = _shiftLocalId;
    if (_persist && id != null) {
      await db.locationDao.insertPing(
        LocationPingsTableCompanion.insert(
          shiftLocalId: id,
          ts: fix.at,
          lat: fix.point.lat,
          lon: fix.point.lon,
          accuracyM: fix.accuracyM,
          speed: Value(fix.speedMps),
        ),
      );
    }
    _scheduleRepolicy();
  }

  static LocationAccuracy _accuracy(SamplingAccuracy a) => switch (a) {
    SamplingAccuracy.high => LocationAccuracy.high,
    SamplingAccuracy.medium => LocationAccuracy.medium,
    SamplingAccuracy.low => LocationAccuracy.low,
  };

  void dispose() {
    unawaited(stop());
    unawaited(_positions.close());
  }
}

@Riverpod(keepAlive: true)
ShiftLocationTracker shiftLocationTracker(Ref ref) {
  final tracker = ShiftLocationTracker(db: ref.watch(appDatabaseProvider));
  ref.onDispose(tracker.dispose);
  return tracker;
}

/// The latest shift fix (null outside a shift). Only the position marker layer listens to it.
@Riverpod(keepAlive: true)
Stream<LocationFix> shiftPosition(Ref ref) => ref.watch(shiftLocationTrackerProvider).positions;
