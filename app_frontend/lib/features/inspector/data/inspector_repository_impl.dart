import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:hawa_api/hawa_api.dart' as api;
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/core/media/image_processor.dart';
import 'package:hawa_app/core/network/fake/fake_backend.dart';
import 'package:hawa_app/core/network/fake/fake_backend_provider.dart';
import 'package:hawa_app/core/network/fake/fake_call.dart';
import 'package:hawa_app/core/network/hawa_api_provider.dart';
import 'package:hawa_app/core/network/interceptors/problem_json_interceptor.dart';
import 'package:hawa_app/core/realtime/realtime_dispatcher.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/storage/secure_token_store.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:hawa_app/core/sync/outbox_op.dart';
import 'package:hawa_app/core/sync/outbox_repository.dart';
import 'package:hawa_app/core/utils/clock.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/features/inspector/domain/inspection_target.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'inspector_repository_impl.g.dart';

/// `GET /v1/inspections?status=assigned` and `GET /v1/inspections/{id}` as plain JSON.
abstract interface class InspectorRemoteSource {
  Future<Map<String, Object?>> list();

  Future<Map<String, Object?>> get(String id);
}

Map<String, Object?> _plain(Object o) => jsonDecode(jsonEncode(o)) as Map<String, Object?>;

class HttpInspectorRemoteSource implements InspectorRemoteSource {
  HttpInspectorRemoteSource(this._api);

  final api.HawaApi _api;

  @override
  Future<Map<String, Object?>> list() async {
    try {
      return _plain(
        (await _api.getInspectionsApi().inspectionsList(status: 'assigned')).data!.toJson(),
      );
    } on DioException catch (e) {
      throw failureOf(e);
    }
  }

  @override
  Future<Map<String, Object?>> get(String id) async {
    try {
      return _plain((await _api.getInspectionsApi().inspectionsGet(id: id)).data!.toJson());
    } on DioException catch (e) {
      throw failureOf(e);
    }
  }
}

class FakeInspectorRemoteSource implements InspectorRemoteSource {
  FakeInspectorRemoteSource(this._backend, this._tokens);

  final FakeBackend _backend;
  final TokenStore _tokens;

  @override
  Future<Map<String, Object?>> list() => fakeCall(
    () async => _backend.inspectionsList(status: 'assigned', token: await _tokens.readAccess()),
  );

  @override
  Future<Map<String, Object?>> get(String id) =>
      fakeCall(() async => _backend.inspectionGet(id, token: await _tokens.readAccess()));
}

/// The backend has no inspection endpoints yet: fake unless `inspector` is in REAL_FEATURES.
@Riverpod(keepAlive: true)
InspectorRemoteSource inspectorRemoteSource(Ref ref) => Env.isFake('inspector')
    ? FakeInspectorRemoteSource(ref.watch(fakeBackendProvider), ref.watch(tokenStoreProvider))
    : HttpInspectorRemoteSource(ref.watch(hawaApiProvider));

/// I1–I4: cache-first targets and evidence; arrival and the outcome go through the outbox
/// (`task_status` for task-backed targets, `photo_upload` → `inspection_close`).
class InspectorRepository {
  InspectorRepository({
    required this.db,
    required this.remote,
    required this.outbox,
    required this.images,
    required this.settings,
    required this.now,
  });

  final AppDatabase db;
  final InspectorRemoteSource remote;
  final OutboxRepository outbox;
  final ImageProcessor images;
  final SettingsStore settings;
  final DateTime Function() now;

  static const listKey = 'inspector:targets';
  static const onSiteKey = 'inspector:on_site';
  static const closedKey = 'inspector:closed_local';
  static String detailKey(String id) => 'inspector:detail:$id';

  Future<Set<String>> _set(String key) async => {
    ...?((await db.cacheDao.getJson(key))?.json['ids'] as List<Object?>?)?.whereType<String>(),
  };

  /// Open targets, most urgent first; cases closed on the phone drop out at once.
  Stream<List<InspectionTarget>> watchTargets() async* {
    await for (final c in db.cacheDao.watchJson(listKey)) {
      final onSite = await _set(onSiteKey);
      final closed = await _set(closedKey);
      final items =
          [
                for (final j in (c?.json['items'] as List<Object?>?) ?? const [])
                  if (j is Map<String, Object?>) InspectionTarget.fromJson(j, onSite: onSite),
              ]
              .whereType<InspectionTarget>()
              .where((t) => !t.status.isClosed && !closed.contains(t.id))
              .toList()
            ..sort(
              (a, b) => a.priority != b.priority
                  ? a.priority.compareTo(b.priority)
                  : b.createdAt.compareTo(a.createdAt),
            );
      yield items;
    }
  }

  Future<void> refreshTargets() async =>
      db.cacheDao.putJson(listKey, await remote.list(), fetchedAt: now().toUtc());

  Stream<DateTime?> watchTargetsFetchedAt() =>
      db.cacheDao.watchJson(listKey).map((c) => c?.fetchedAt);

  /// The evidence bundle once opened online; before that, the list row (text only).
  Stream<TargetEvidence?> watchEvidence(String id) async* {
    await for (final c in db.cacheDao.watchJson(detailKey(id))) {
      final onSite = await _set(onSiteKey);
      if (c != null) {
        yield TargetEvidence.fromJson(c.json, onSite: onSite);
        continue;
      }
      final list = await db.cacheDao.getJson(listKey);
      final row = ((list?.json['items'] as List<Object?>?) ?? const [])
          .whereType<Map<String, Object?>>()
          .where((j) => j['id'] == id)
          .firstOrNull;
      yield row == null ? null : TargetEvidence.fromJson(row, onSite: onSite);
    }
  }

  Future<void> refreshEvidence(String id) async =>
      db.cacheDao.putJson(detailKey(id), await remote.get(id), fetchedAt: now().toUtc());

  Future<void> _addTo(String key, String id) async {
    final ids = await _set(key)
      ..add(id);
    await db.cacheDao.putJson(key, {'ids': ids.toList()}, fetchedAt: now().toUtc());
  }

  /// `en_route` for task-backed targets (before navigation).
  Future<void> enRoute(InspectionTarget t) async {
    if (t.taskId != null) await _taskStatus(t.taskId!, TaskStatus.enRoute);
  }

  /// "Arrived": `in_progress` (on site) for task-backed targets; local only otherwise.
  Future<void> arrived(InspectionTarget t) async {
    await _addTo(onSiteKey, t.id);
    if (t.taskId != null) await _taskStatus(t.taskId!, TaskStatus.inProgress);
    // Re-emit the evidence stream with the local on-site flag.
    final cached = await db.cacheDao.getJson(detailKey(t.id));
    if (cached != null) {
      await db.cacheDao.putJson(detailKey(t.id), cached.json, fetchedAt: cached.fetchedAt);
    }
  }

  Future<void> _taskStatus(String taskId, TaskStatus status) => outbox.enqueue(
    kind: OpKind.taskStatus,
    orderingKey: OrderingKeys.task(taskId),
    payload: {
      'task_id': taskId,
      'status': status.wire,
      'client_ts': now().toUtc().toIso8601String(),
    },
  );

  /// I4: photos (EXIF stripped) then `inspection_close`, in one transaction. Exactly once on the
  /// server via the idempotency key; the case leaves the list at once.
  Future<void> close(
    String inspectionId, {
    required InspectionStatus outcome,
    required List<String> photoPaths,
    String? notes,
    GeoPoint? location,
  }) async {
    final processed = [
      for (final p in photoPaths) await images.process(p, dataSaver: settings.dataSaver),
    ];
    final t = now().toUtc();
    await db.transaction(() async {
      String? lastPhotoOp;
      for (final img in processed) {
        await db.mediaDao.insertMedia(
          MediaFilesTableCompanion.insert(
            id: img.id,
            path: img.file.path,
            sha256: img.sha256,
            bytes: img.bytes,
            purpose: 'inspection_photo',
            state: 'local',
            createdAt: t,
            thumbPath: Value(img.thumb?.path),
          ),
        );
        lastPhotoOp = await outbox.enqueue(
          kind: OpKind.photoUpload,
          orderingKey: OrderingKeys.media(img.id),
          payload: {'media_id': img.id},
        );
      }
      await outbox.enqueue(
        kind: OpKind.inspectionClose,
        orderingKey: OrderingKeys.inspection(inspectionId),
        dependsOn: lastPhotoOp,
        payload: {
          'inspection_id': inspectionId,
          'outcome': outcome.wire,
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
          'media_ids': [for (final img in processed) img.id],
          'closed_at': t.toIso8601String(),
          if (location != null) 'location': {'lat': location.lat, 'lon': location.lon},
        },
      );
      await _addTo(closedKey, inspectionId);
    });
    // Re-emit the list without the closed case.
    final list = await db.cacheDao.getJson(listKey);
    if (list != null) await db.cacheDao.putJson(listKey, list.json, fetchedAt: list.fetchedAt);
  }
}

@riverpod
InspectorRepository inspectorRepository(Ref ref) => InspectorRepository(
  db: ref.watch(appDatabaseProvider),
  remote: ref.watch(inspectorRemoteSourceProvider),
  outbox: ref.watch(outboxRepositoryProvider),
  images: ref.watch(imageProcessorProvider),
  settings: ref.watch(settingsStoreProvider),
  now: ref.watch(appClockProvider).now,
);

/// Registers the `inspection.` realtime handler: any inspection event refreshes the targets.
@Riverpod(keepAlive: true)
bool inspectorEventApplier(Ref ref) {
  ref.watch(realtimeDispatcherProvider).on('inspection.', (_) async {
    try {
      await ref.read(inspectorRepositoryProvider).refreshTargets();
    } on Object {
      // The next sync trigger retries.
    }
  });
  return true;
}
