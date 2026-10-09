import 'dart:async';

import 'package:hawa_app/core/location/location_service.dart';
import 'package:hawa_app/core/location/shift_location_tracker.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:hawa_app/core/sync/outbox_op.dart';
import 'package:hawa_app/core/sync/outbox_repository.dart';
import 'package:hawa_app/core/sync/sync_triggers.dart';
import 'package:hawa_app/core/utils/clock.dart';
import 'package:hawa_app/features/driver_route/application/arrival_watcher.dart';
import 'package:hawa_app/features/driver_route/data/driver_route_repository_impl.dart';
import 'package:hawa_app/features/driver_route/domain/shift.dart';
import 'package:hawa_app/features/driver_route/domain/today_route.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shift_controller.g.dart';

class ShiftUiState {
  const ShiftUiState({
    this.active = false,
    this.shiftId,
    this.startedAt,
    this.needsResume = false,
    this.autoEndPrompt = false,
    this.autoEnded = false,
    this.busy = false,
  });

  final bool active;
  final String? shiftId;
  final DateTime? startedAt;

  /// The app was killed or the phone rebooted mid-shift: offer to resume tracking (never
  /// restart location without the user; failure matrix rows 5–6).
  final bool needsResume;

  /// All stops terminal and the scheduled end passed: "End shift?".
  final bool autoEndPrompt;

  /// Ended automatically at scheduled end + 2 h.
  final bool autoEnded;
  final bool busy;

  ShiftUiState copyWith({
    bool? active,
    String? shiftId,
    DateTime? startedAt,
    bool? needsResume,
    bool? autoEndPrompt,
    bool? autoEnded,
    bool? busy,
  }) => ShiftUiState(
    active: active ?? this.active,
    shiftId: shiftId ?? this.shiftId,
    startedAt: startedAt ?? this.startedAt,
    needsResume: needsResume ?? this.needsResume,
    autoEndPrompt: autoEndPrompt ?? this.autoEndPrompt,
    autoEnded: autoEnded ?? this.autoEnded,
    busy: busy ?? this.busy,
  );
}

/// Start/End shift (ARCHITECTURE §11): location only between them, through a foreground
/// service with a visible notification. `shift_start` / `shift_end` go through the outbox
/// (proposed endpoints). Pings are uploaded only while the HawaTag cannot report position.
@Riverpod(keepAlive: true)
class ShiftController extends _$ShiftController {
  Timer? _tick;
  String _title = '';
  String _body = '';

  @override
  ShiftUiState build() {
    ref.onDispose(() => _tick?.cancel());
    final saved = ref.read(settingsStoreProvider).activeShift;
    final tracker = ref.read(shiftLocationTrackerProvider);
    if (saved != null && !tracker.active) {
      return ShiftUiState(
        shiftId: saved['shift_id'] as String?,
        startedAt: DateTime.tryParse(saved['started_at'] as String? ?? ''),
        needsResume: true,
      );
    }
    return const ShiftUiState();
  }

  /// [notificationTitle]/[notificationBody] are the localized foreground-service texts.
  Future<void> start(
    TodayRoute route, {
    required String notificationTitle,
    required String notificationBody,
  }) async {
    _title = notificationTitle;
    _body = notificationBody;
    state = state.copyWith(busy: true);
    final now = ref.read(appClockProvider).now().toUtc();
    final shift =
        route.shift ??
        Shift(
          id: 'local:${route.date}',
          status: .scheduled,
          start: now,
          end: now.add(const Duration(hours: 6)),
        );
    await _startTracking(route, shift.id);
    final fix =
        ref.read(shiftLocationTrackerProvider).last ??
        await ref.read(locationServiceProvider).currentFix(timeout: const Duration(seconds: 5));
    if (route.shift != null) {
      await ref.read(driverRouteRepositoryProvider).startShift(shift, location: fix?.point);
    }
    await ref.read(settingsStoreProvider).setActiveShift({
      'shift_id': shift.id,
      'started_at': now.toIso8601String(),
      'date': route.date,
    });
    state = ShiftUiState(active: true, shiftId: shift.id, startedAt: now);
  }

  /// After a restart mid-shift, the user taps Resume.
  Future<void> resume(
    TodayRoute route, {
    required String notificationTitle,
    required String notificationBody,
  }) async {
    _title = notificationTitle;
    _body = notificationBody;
    final id = state.shiftId ?? route.shift?.id ?? 'local:${route.date}';
    await _startTracking(route, id);
    state = state.copyWith(active: true, needsResume: false);
  }

  Future<void> _startTracking(TodayRoute route, String shiftId) async {
    final tracker = ref.read(shiftLocationTrackerProvider);
    await tracker.start(
      shiftLocalId: shiftId,
      notificationTitle: _title,
      notificationBody: _body,
      persistPings: route.asset?.tagCannotConfirm ?? false,
    );
    ref.read(arrivalWatcherProvider)
      ..start()
      ..updateRoute(route);
    ref.read(shiftActiveFlagProvider.notifier).set(active: true);
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 60), (_) => unawaited(_onTick()));
  }

  /// Keeps the geofence target and sampling current as stops complete.
  void routeChanged(TodayRoute? route) {
    if (!state.active || route == null) return;
    ref.read(arrivalWatcherProvider).updateRoute(route);
    ref
        .read(shiftLocationTrackerProvider)
        .setPersistPings(persist: route.asset?.tagCannotConfirm ?? false);
  }

  Future<void> end(TodayRoute? route) async {
    state = state.copyWith(busy: true);
    _tick?.cancel();
    await _flushPings();
    await ref.read(arrivalWatcherProvider).stop();
    await ref.read(shiftLocationTrackerProvider).stop();
    await ref.read(appDatabaseProvider).locationDao.purgeAll();
    ref.read(shiftActiveFlagProvider.notifier).set(active: false);
    final shift = route?.shift;
    if (shift != null && state.shiftId == shift.id) {
      await ref.read(driverRouteRepositoryProvider).endShift(shift);
    }
    await ref.read(settingsStoreProvider).setActiveShift(null);
    state = const ShiftUiState();
  }

  void dismissAutoEnd() => state = state.copyWith(autoEndPrompt: false);

  Future<void> _onTick() async {
    await _flushPings();
    final route = await _currentRoute();
    final shift = route?.shift;
    if (route == null || shift == null) return;
    final now = ref.read(appClockProvider).now().toUtc();
    final allTerminal = route.stops.every((s) => s.shownStatus.isTerminal);
    if (now.isAfter(shift.end.add(const Duration(hours: 2)))) {
      await end(route);
      state = state.copyWith(autoEnded: true);
    } else if (allTerminal && now.isAfter(shift.end) && !state.autoEndPrompt) {
      state = state.copyWith(autoEndPrompt: true);
    }
  }

  Future<TodayRoute?> _currentRoute() =>
      ref.read(driverRouteRepositoryProvider).watchRoute(ref.read(serviceDateProvider)).first;

  /// `location_batch` every 60 s while pings are kept (HawaTag offline); > 6 h old batches expire.
  Future<void> _flushPings() async {
    final id = state.shiftId;
    if (id == null || id.startsWith('local:')) return;
    final db = ref.read(appDatabaseProvider);
    final pings = await db.locationDao.unbatched(id);
    if (pings.isEmpty) return;
    await db.transaction(() async {
      await ref
          .read(outboxRepositoryProvider)
          .enqueue(
            kind: OpKind.locationBatch,
            orderingKey: OrderingKeys.locations(id),
            payload: {
              'shift_id': id,
              'pings': [
                for (final p in pings)
                  {
                    'ts': p.ts.toUtc().toIso8601String(),
                    'lat': p.lat,
                    'lon': p.lon,
                    'accuracy_m': p.accuracyM,
                    if (p.speed != null) 'speed_kmh': p.speed! * 3.6,
                  },
              ],
            },
          );
      await db.locationDao.markBatched([for (final p in pings) p.id]);
    });
  }
}
