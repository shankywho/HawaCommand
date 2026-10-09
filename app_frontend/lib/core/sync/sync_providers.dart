import 'package:hawa_app/core/errors/crash_reporter.dart';
import 'package:hawa_app/core/media/image_processor.dart';
import 'package:hawa_app/core/media/upload_service.dart';
import 'package:hawa_app/core/network/connectivity_service.dart';
import 'package:hawa_app/core/network/hawa_api_provider.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:hawa_app/core/sync/conflict_banner_bus.dart';
import 'package:hawa_app/core/sync/conflict_resolver.dart';
import 'package:hawa_app/core/sync/executors/alert_ack_executor.dart';
import 'package:hawa_app/core/sync/executors/inspection_close_executor.dart';
import 'package:hawa_app/core/sync/executors/location_batch_executor.dart';
import 'package:hawa_app/core/sync/executors/op_executor.dart';
import 'package:hawa_app/core/sync/executors/photo_upload_executor.dart';
import 'package:hawa_app/core/sync/executors/profile_update_executor.dart';
import 'package:hawa_app/core/sync/executors/push_token_executor.dart';
import 'package:hawa_app/core/sync/executors/report_submit_executor.dart';
import 'package:hawa_app/core/sync/executors/shift_executor.dart';
import 'package:hawa_app/core/sync/executors/task_ack_executor.dart';
import 'package:hawa_app/core/sync/executors/task_status_executor.dart';
import 'package:hawa_app/core/sync/outbox_drainer.dart';
import 'package:hawa_app/core/sync/outbox_repository.dart';
import 'package:hawa_app/core/utils/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_providers.g.dart';

@Riverpod(keepAlive: true)
CrashReporter crashReporter(Ref ref) => CrashReporter(enabled: false);

/// Upload progress per media id (0–1), shown in `/settings/sync` and on photo strips.
@Riverpod(keepAlive: true)
class UploadProgress extends _$UploadProgress {
  @override
  Map<String, double> build() => const {};

  void report(String mediaId, double value) => state = {...state, mediaId: value};
}

@Riverpod(keepAlive: true)
List<OpExecutor> opExecutors(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final api = ref.watch(mutationApiProvider);
  final clock = ref.watch(appClockProvider);
  return [
    TaskAckExecutor(api, db),
    TaskStatusExecutor(api, db),
    InspectionCloseExecutor(
      api,
      db,
      onClosed: (inspectionId, {required applied}) async {
        // Inspector targets are task rows keyed by inspection id (OFFLINE_AND_SYNC §2).
        await db.taskDao.applyServerStatus(inspectionId, status: 'done', clearPending: true);
        if (!applied) {
          ref
              .read(conflictBannerBusProvider.notifier)
              .publish(
                ConflictNotice(
                  kind: ConflictKind.caseClosed,
                  entityId: inspectionId,
                  at: clock.now().toUtc(),
                ),
              );
        }
      },
    ),
    PhotoUploadExecutor(
      db,
      ref.watch(uploadServiceProvider),
      clock,
      recompress: (file) => ref.read(imageProcessorProvider).recompressSmaller(file),
      onProgress: (id, p) => ref.read(uploadProgressProvider.notifier).report(id, p),
    ),
    ReportSubmitExecutor(api, db, clock),
    AlertAckExecutor(api),
    ShiftExecutor(api, start: true),
    ShiftExecutor(api, start: false),
    LocationBatchExecutor(api),
    PushTokenExecutor(api),
    ProfileUpdateExecutor(api),
  ];
}

@Riverpod(keepAlive: true)
ConflictResolver conflictResolver(Ref ref) => ConflictResolver(
  db: ref.watch(appDatabaseProvider),
  clock: ref.watch(appClockProvider),
  publish: (n) => ref.read(conflictBannerBusProvider.notifier).publish(n),
);

@Riverpod(keepAlive: true)
OutboxDrainer outboxDrainer(Ref ref) {
  final drainer = OutboxDrainer(
    db: ref.watch(appDatabaseProvider),
    executors: ref.watch(opExecutorsProvider),
    clock: ref.watch(appClockProvider),
    userId: () {
      try {
        return ref.mounted ? ref.read(currentUserIdProvider) : null;
      } catch (_) {
        return null;
      }
    },
    isOffline: () {
      try {
        return ref.mounted ? (ref.read(networkStatusProvider).value?.isOffline ?? false) : false;
      } catch (_) {
        return false;
      }
    },
    isMobileData: () {
      try {
        return ref.mounted
            ? ((ref.read(onMobileDataProvider).value ?? false) ||
                ref.read(settingsStoreProvider).dataSaver)
            : false;
      } catch (_) {
        return false;
      }
    },
    publish: (n) => ref.read(conflictBannerBusProvider.notifier).publish(n),
    crash: ref.watch(crashReporterProvider),
  );
  ref.read(outboxKickProvider).bind(drainer.kick);
  ref.onDispose(drainer.dispose);
  return drainer;
}

/// Whether the drainer is working right now (sync chip spinner).
@riverpod
Stream<bool> outboxActive(Ref ref) => ref.watch(outboxDrainerProvider).activity;
