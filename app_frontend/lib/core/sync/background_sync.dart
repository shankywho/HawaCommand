import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/storage/secure_token_store.dart';
import 'package:hawa_app/core/sync/outbox_repository.dart';
import 'package:hawa_app/core/sync/sync_providers.dart';
import 'package:logging/logging.dart';
import 'package:workmanager/workmanager.dart';

/// Background drain (OFFLINE_AND_SYNC §5.6): a workmanager periodic task every 15 min (the
/// Android minimum) with network required, plus one-off tasks scheduled from the FCM background
/// handler. The callback dispatcher lives in `app/background_entry.dart` because it needs the
/// app's provider overrides; it calls [runBackgroundSync].
abstract final class BackgroundSync {
  static const periodicTask = 'hawa.outbox.periodic';
  static const oneOffTask = 'hawa.outbox.oneoff';
  static final _log = Logger('bg');

  static Future<void> schedulePeriodic() async {
    try {
      await Workmanager().registerPeriodicTask(
        periodicTask,
        periodicTask,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } on Object catch (e) {
      _log.warning('periodic sync not scheduled', e);
    }
  }

  static Future<void> scheduleOneOff() async {
    try {
      await Workmanager().registerOneOffTask(
        '$oneOffTask.${DateTime.now().millisecondsSinceEpoch}',
        oneOffTask,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } on Object catch (e) {
      _log.warning('one-off sync not scheduled', e);
    }
  }

  static Future<void> cancelAll() async {
    try {
      await Workmanager().cancelAll();
    } on Object catch (e) {
      _log.warning('cancel failed', e);
    }
  }
}

/// Drains the outbox with its own DB connection (WAL makes the second connection safe).
Future<bool> runBackgroundSync(ProviderContainer container) async {
  final tokens = container.read(tokenStoreProvider);
  final userId = await tokens.readUserId();
  if (userId == null) return true;
  container.read(currentUserIdProvider.notifier).set(userId);
  final drainer = container.read(outboxDrainerProvider);
  await drainer.start();
  await drainer.drainNow(budget: const Duration(seconds: 25));
  await container.read(appDatabaseProvider).outboxDao.prune(DateTime.now().toUtc());
  return true;
}
