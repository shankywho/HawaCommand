import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hawa_app/core/network/connectivity_service.dart';
import 'package:hawa_app/core/sync/sync_providers.dart';
import 'package:hawa_app/core/utils/clock.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_triggers.g.dart';

enum SyncTriggerKind {
  connectivityRegained,
  resumed,
  push,
  wsReconnected,
  periodic,
  dateRollover,
  manual,
}

class SyncTrigger {
  const SyncTrigger(this.kind, this.seq, {this.scope});

  final SyncTriggerKind kind;
  final int seq;

  /// Optional scope hint (`tasks`, `alerts`, `reports`, …) for push-driven refreshes.
  final String? scope;
}

/// Whether a field shift is on (sets the periodic cadence: 60 s on shift, 5 min otherwise).
@Riverpod(keepAlive: true)
class ShiftActiveFlag extends _$ShiftActiveFlag {
  @override
  bool build() => false;

  // A notifier command (`ref.read(p.notifier).set(…)`) reads better than a setter here.
  // ignore: use_setters_to_change_properties
  void set({required bool active}) => state = active;
}

/// The IST service date; flips at 00:00 IST.
@Riverpod(keepAlive: true)
class ServiceDate extends _$ServiceDate {
  Timer? _timer;

  @override
  String build() {
    final clock = ref.watch(appClockProvider);
    ref.onDispose(() => _timer?.cancel());
    final now = clock.now().toUtc();
    final today = IstTime.serviceDate(now);
    final next = IstTime.startOfDayUtc(IstTime.addDays(today, 1));
    _timer = Timer(next.difference(now) + const Duration(seconds: 1), ref.invalidateSelf);
    return today;
  }
}

/// Sync triggers (OFFLINE_AND_SYNC §8). Every trigger kicks the drainer; feature controllers
/// `ref.listen` to this provider to refresh their scopes (stale-while-revalidate).
@Riverpod(keepAlive: true)
class SyncTriggers extends _$SyncTriggers {
  Timer? _periodic;
  Timer? _debounce;
  AppLifecycleListener? _lifecycle;
  int _seq = 0;

  @override
  SyncTrigger? build() {
    ref
      ..listen(networkStatusProvider, (prev, next) {
        final was = prev?.value;
        final now = next.value;
        if (now == NetworkStatus.online && was != NetworkStatus.online) {
          _debounce?.cancel();
          _debounce = Timer(
            const Duration(seconds: 3),
            () => fire(SyncTriggerKind.connectivityRegained),
          );
        }
      })
      ..listen(shiftActiveFlagProvider, (_, active) => _restartPeriodic(active: active))
      ..listen(serviceDateProvider, (prev, next) {
        if (prev != null && prev != next) fire(SyncTriggerKind.dateRollover);
      })
      ..onDispose(() {
        _periodic?.cancel();
        _debounce?.cancel();
        _lifecycle?.dispose();
      });
    _lifecycle = AppLifecycleListener(onResume: () => fire(SyncTriggerKind.resumed));
    _restartPeriodic(active: ref.read(shiftActiveFlagProvider));
    return null;
  }

  void fire(SyncTriggerKind kind, {String? scope}) {
    ref.read(outboxDrainerProvider).kick();
    state = SyncTrigger(kind, ++_seq, scope: scope);
  }

  void _restartPeriodic({required bool active}) {
    _periodic?.cancel();
    _periodic = Timer.periodic(
      active ? const Duration(seconds: 60) : const Duration(minutes: 5),
      (_) => fire(SyncTriggerKind.periodic),
    );
  }
}
