import 'dart:async';

import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/location/location_service.dart';
import 'package:hawa_app/core/network/command_center_api.dart';
import 'package:hawa_app/core/network/interceptors/problem_json_interceptor.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:hawa_app/core/utils/clock.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/core/utils/localized_text.dart';
import 'package:hawa_app/features/citizen_air/data/citizen_air_repository_impl.dart';
import 'package:hawa_app/features/citizen_air/domain/air_snapshot.dart';
import 'package:hawa_app/features/citizen_air/domain/alert_subscription.dart';
import 'package:hawa_app/features/citizen_air/domain/manual_area.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'air_near_me_controller.g.dart';

/// Where "near me" is: a coarse fix (kept on the phone) or a hand-picked area.
class CitizenArea {
  const CitizenArea({required this.point, this.manual});

  final GeoPoint point;
  final ManualArea? manual;

  GeoBox get box => Geo.snappedBox(point);
}

class AirNearMeState {
  const AirNearMeState({
    this.area,
    this.cached,
    this.pick = AirPick.none,
    this.locationDenied = false,
    this.loading = true,
    this.refreshing = false,
    this.error,
  });

  final CitizenArea? area;
  final CachedAir? cached;
  final AirPick pick;

  /// Location is off or denied and no area is picked: show the area picker (never a dead end).
  final bool locationDenied;
  final bool loading;
  final bool refreshing;
  final Failure? error;

  AirNearMeState copyWith({
    CitizenArea? area,
    CachedAir? cached,
    AirPick? pick,
    bool? locationDenied,
    bool? loading,
    bool? refreshing,
    Failure? error,
    bool clearError = false,
  }) => AirNearMeState(
    area: area ?? this.area,
    cached: cached ?? this.cached,
    pick: pick ?? this.pick,
    locationDenied: locationDenied ?? this.locationDenied,
    loading: loading ?? this.loading,
    refreshing: refreshing ?? this.refreshing,
    error: clearError ? null : error ?? this.error,
  );
}

/// C1 Air near me: the snapped ~1 km box around a coarse position (or a picked area) is the only
/// thing sent; the user's own cell is chosen on the phone. Stale after 30 min.
@riverpod
class AirNearMeController extends _$AirNearMeController {
  static const staleAfter = Duration(minutes: 30);
  StreamSubscription<CachedAir?>? _sub;

  @override
  AirNearMeState build() {
    ref.onDispose(() => _sub?.cancel());
    unawaited(Future.microtask(_init));
    return const AirNearMeState();
  }

  Future<void> _init() async {
    final manual = ManualArea.fromJson(ref.read(settingsStoreProvider).manualArea);
    if (manual != null) {
      await _setArea(CitizenArea(point: manual.point, manual: manual));
      return;
    }
    await useLocation(ask: false);
    if (state.area == null) {
      final defaultArea = ManualArea.delhi.first;
      await _setArea(CitizenArea(point: defaultArea.point, manual: defaultArea));
    }
  }


  /// Coarse fix only; when location is unavailable, falls back to the area picker.
  Future<void> useLocation({bool ask = true}) async {
    final loc = ref.read(locationServiceProvider);
    var status = await loc.status();
    if (status != LocationPermissionState.granted && ask) status = await loc.request();
    if (status != LocationPermissionState.granted) {
      if (ref.mounted) state = state.copyWith(locationDenied: true, loading: false);
      return;
    }
    final fix = await loc.currentFix(precise: false, timeout: const Duration(seconds: 10));
    if (!ref.mounted) return;
    if (fix == null) {
      state = state.copyWith(locationDenied: true, loading: false);
      return;
    }
    await ref.read(settingsStoreProvider).setManualArea(null);
    await _setArea(CitizenArea(point: Geo.coarse(fix.point)));
  }

  Future<void> pickArea(ManualArea area) async {
    await ref.read(settingsStoreProvider).setManualArea(area.toJson());
    await _setArea(CitizenArea(point: area.point, manual: area));
  }

  Future<void> _setArea(CitizenArea area) async {
    if (!ref.mounted) return;
    state = AirNearMeState(area: area);
    await _sub?.cancel();
    final repo = ref.read(citizenAirRepositoryProvider);
    _sub = repo.watchAir(area.box).listen((cached) {
      if (!ref.mounted) return;
      state = state.copyWith(
        cached: cached,
        pick: AirPick.of(cached?.snapshot, area.point),
        loading: cached == null && state.refreshing,
      );
    });
    final cached = await repo.watchAir(area.box).first;
    final now = ref.read(appClockProvider).now().toUtc();
    if (cached == null || now.difference(cached.fetchedAt) > staleAfter) await refresh();
    if (ref.mounted) state = state.copyWith(loading: false);
  }

  Future<void> refresh() async {
    final area = state.area;
    if (area == null) return;
    state = state.copyWith(refreshing: true, clearError: true);
    try {
      await ref.read(citizenAirRepositoryProvider).refreshAir(area.box);
      if (ref.mounted) state = state.copyWith(refreshing: false, loading: false);
    } on Object catch (e) {
      if (ref.mounted) {
        state = state.copyWith(refreshing: false, loading: false, error: failureOf(e));
      }
    }
  }
}

/// C2: the cached subscription, refreshed once per open.
@riverpod
Stream<AlertSubscriptionPrefs?> alertSubscription(Ref ref) {
  final repo = ref.watch(citizenAirRepositoryProvider);
  unawaited(repo.refreshSubscription().catchError((Object _) {}));
  return repo.watchSubscription();
}

/// C2 writes: optimistic cache + outbox `profile_update`.
@riverpod
class SubscriptionEditor extends _$SubscriptionEditor {
  @override
  void build() {}

  Future<void> save(AlertSubscriptionPrefs prefs) =>
      ref.read(citizenAirRepositoryProvider).saveSubscription(prefs);

  /// The cached place name around [point], if C1 has fetched it.
  Future<LocalizedText?> placeFor(GeoPoint point) =>
      ref.read(citizenAirRepositoryProvider).placeFor(point);
}

/// Dynamic diurnal safe-window calculations from the real backend AI model.
final safeBreathWindowProvider = FutureProvider.autoDispose<Map<String, Object?>>((ref) async {
  final api = ref.watch(commandCenterApiProvider);
  return api.safeWindow();
});

