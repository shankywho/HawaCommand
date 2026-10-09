import 'dart:async';

import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/location/location_service.dart';
import 'package:hawa_app/core/media/photo_capture.dart';
import 'package:hawa_app/core/network/interceptors/problem_json_interceptor.dart';
import 'package:hawa_app/core/sync/sync_triggers.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/features/inspector/data/inspector_repository_impl.dart';
import 'package:hawa_app/features/inspector/domain/inspection_target.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'inspector_controllers.g.dart';

/// I1: cached targets; refreshed on open and on every sync trigger (push, reconnect…).
@riverpod
Stream<List<InspectionTarget>> inspectionTargets(Ref ref) {
  final repo = ref.watch(inspectorRepositoryProvider);
  ref.listen(
    syncTriggersProvider,
    (_, _) => unawaited(ref.read(targetsRefreshProvider.notifier).refresh()),
  );
  unawaited(Future.microtask(() => ref.read(targetsRefreshProvider.notifier).refresh()));
  return repo.watchTargets();
}

@riverpod
Stream<DateTime?> targetsFetchedAt(Ref ref) =>
    ref.watch(inspectorRepositoryProvider).watchTargetsFetchedAt();

/// Last refresh failure for the banner.
@Riverpod(keepAlive: true)
class TargetsRefresh extends _$TargetsRefresh {
  @override
  Failure? build() => null;

  Future<void> refresh() async {
    try {
      await ref.read(inspectorRepositoryProvider).refreshTargets();
      if (ref.mounted) state = null;
    } on Object catch (e) {
      if (ref.mounted) state = failureOf(e);
    }
  }
}

/// I3: the evidence bundle (cached after the first online open).
@riverpod
Stream<TargetEvidence?> targetEvidence(Ref ref, String id) {
  final repo = ref.watch(inspectorRepositoryProvider);
  unawaited(repo.refreshEvidence(id).catchError((Object _) {}));
  return repo.watchEvidence(id);
}

@riverpod
class InspectorActions extends _$InspectorActions {
  @override
  void build() {}

  Future<void> enRoute(InspectionTarget t) => ref.read(inspectorRepositoryProvider).enRoute(t);

  Future<void> arrived(InspectionTarget t) => ref.read(inspectorRepositoryProvider).arrived(t);

  Future<String?> takePhoto() => ref.read(photoCaptureProvider).capture();

  /// I4 Save: works offline; the draft is the outbox itself.
  Future<void> close(
    String id, {
    required InspectionStatus outcome,
    required List<String> photos,
    String? notes,
  }) async {
    final fix = await ref
        .read(locationServiceProvider)
        .currentFix(timeout: const Duration(seconds: 6));
    await ref
        .read(inspectorRepositoryProvider)
        .close(id, outcome: outcome, photoPaths: photos, notes: notes, location: fix?.point);
  }
}
