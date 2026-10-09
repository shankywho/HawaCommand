import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_service.g.dart';

enum NetworkStatus { online, offline, unknown }

/// Dev tools "Go offline": forces the offline state and makes fake sources and the Dio chain
/// fail with a network failure (PLAN §6).
@Riverpod(keepAlive: true)
class ForcedOffline extends _$ForcedOffline {
  @override
  bool build() => ref.watch(settingsStoreProvider).fakeOffline;

  Future<void> set({required bool offline}) async {
    await ref.read(settingsStoreProvider).setFakeOffline(on: offline);
    state = offline;
  }
}

/// connectivity_plus → online / offline / unknown, merged with the dev override.
/// Connectivity does not prove internet: the first real request is the internet test (§8).
@Riverpod(keepAlive: true)
Stream<NetworkStatus> networkStatus(Ref ref) async* {
  final forced = ref.watch(forcedOfflineProvider);
  if (forced) {
    yield NetworkStatus.offline;
    return;
  }
  final connectivity = Connectivity();
  NetworkStatus map(List<ConnectivityResult> r) =>
      r.isEmpty || r.every((c) => c == ConnectivityResult.none)
      ? NetworkStatus.offline
      : NetworkStatus.online;
  try {
    yield map(await connectivity.checkConnectivity());
  } on Exception {
    yield NetworkStatus.unknown;
  }
  yield* connectivity.onConnectivityChanged.map(map);
}

/// Whether the device is on mobile data (one photo upload at a time, no tile prefetch).
@Riverpod(keepAlive: true)
Future<bool> onMobileData(Ref ref) async {
  ref.watch(networkStatusProvider);
  try {
    final r = await Connectivity().checkConnectivity();
    return r.contains(ConnectivityResult.mobile) && !r.contains(ConnectivityResult.wifi);
  } on Exception {
    return false;
  }
}

extension NetworkStatusX on NetworkStatus {
  bool get isOffline => this == NetworkStatus.offline;
}
