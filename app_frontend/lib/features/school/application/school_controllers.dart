import 'dart:async';

import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/network/interceptors/problem_json_interceptor.dart';
import 'package:hawa_app/core/sync/sync_triggers.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/features/school/data/school_repository_impl.dart';
import 'package:hawa_app/features/school/domain/school_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'school_controllers.g.dart';

/// The cached school; every sync trigger refreshes all school data.
@riverpod
Stream<SchoolInfo?> schoolInfo(Ref ref) {
  final repo = ref.watch(schoolRepositoryProvider);
  ref.listen(
    syncTriggersProvider,
    (_, _) => unawaited(ref.read(schoolRefreshProvider.notifier).refresh()),
  );
  unawaited(Future.microtask(() => ref.read(schoolRefreshProvider.notifier).refresh()));
  return repo.watchMe();
}

/// Last refresh failure (cleared on success) for the stale/error banner.
@Riverpod(keepAlive: true)
class SchoolRefresh extends _$SchoolRefresh {
  @override
  Failure? build() => null;

  Future<void> refresh() async {
    final repo = ref.read(schoolRepositoryProvider);
    try {
      final me = await repo.refreshMe();
      if (me == null) return;
      final today = ref.read(serviceDateProvider);
      await Future.wait([
        repo.refreshSafe(me.id, today),
        repo.refreshSafe(me.id, IstTime.addDays(today, 1)),
        repo.refreshIndoor(me.id),
        repo.refreshGrap(me.wardId),
        repo.refreshForecast(me.forecastCellId),
      ]);
      if (ref.mounted) state = null;
    } on Object catch (e) {
      if (ref.mounted) state = failureOf(e);
    }
  }
}

@riverpod
Stream<SafeWindowDay?> safeWindowDay(Ref ref, String date) =>
    ref.watch(schoolRepositoryProvider).watchSafe(date);

@riverpod
Stream<IndoorOutdoor?> indoorOutdoor(Ref ref) => ref.watch(schoolRepositoryProvider).watchIndoor();

@riverpod
Stream<List<GrapDay>> grapOutlook(Ref ref) => ref.watch(schoolRepositoryProvider).watchGrap();

@riverpod
Stream<CellForecast?> cellForecast(Ref ref) => ref.watch(schoolRepositoryProvider).watchForecast();

@riverpod
Stream<DateTime?> schoolFetchedAt(Ref ref) =>
    ref.watch(schoolRepositoryProvider).watchFetchedAt(SchoolRepository.meKey);
