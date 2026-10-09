import 'dart:async';

import 'package:hawa_app/core/location/location_service.dart';
import 'package:hawa_app/core/media/photo_capture.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:hawa_app/core/utils/ids.dart';
import 'package:hawa_app/features/citizen_reports/data/reports_repository_impl.dart';
import 'package:hawa_app/features/citizen_reports/domain/citizen_report.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reports_controllers.g.dart';

/// C6: unsent drafts + the server list (cache first; refreshed on open).
@riverpod
Stream<List<ReportListItem>> myReports(Ref ref) {
  final repo = ref.watch(reportsRepositoryProvider);
  unawaited(repo.refreshMine().catchError((Object _) {}));
  return repo.watchMine();
}

/// C7: cached detail, refreshed on open (and by `report_outcome` pushes via sync triggers).
@riverpod
Stream<ReportDetail?> reportDetail(Ref ref, String id) {
  final repo = ref.watch(reportsRepositoryProvider);
  unawaited(repo.refreshDetail(id).catchError((Object _) {}));
  return repo.watchDetail(id);
}

/// C3 acceptance, stored locally.
@Riverpod(keepAlive: true)
class ReportPrivacyAccepted extends _$ReportPrivacyAccepted {
  static const _key = 'report_privacy';

  @override
  bool build() => ref.read(settingsStoreProvider).educationShown(_key);

  Future<void> accept() async {
    await ref.read(settingsStoreProvider).setEducationShown(_key);
    if (ref.mounted) state = true;
  }
}


enum CaptureStep { idle, capturing, locating, saving }

class CaptureState {
  const CaptureState({this.step = CaptureStep.idle, this.roughM, this.noFix = false});

  final CaptureStep step;

  /// The fix is worse than 50 m.
  final double? roughM;
  final bool noFix;
}

/// C4: camera only (no gallery); a GPS fix is taken in parallel; the photo is stripped of EXIF and
/// stored as a draft. Returns the draft id for C5, or null when cancelled.
@riverpod
class ReportCapture extends _$ReportCapture {
  @override
  CaptureState build() => const CaptureState();

  Future<String?> capture({bool recover = false}) async {
    state = const CaptureState(step: CaptureStep.capturing);
    final loc = ref.read(locationServiceProvider);
    final fixFuture = loc.currentFix(timeout: const Duration(seconds: 12));
    final camera = ref.read(photoCaptureProvider);
    final path = recover ? await camera.retrieveLost() : await camera.capture();
    if (path == null) {
      if (ref.mounted) state = const CaptureState();
      return null;
    }
    if (ref.mounted) state = const CaptureState(step: CaptureStep.locating);
    final fix = await fixFuture;
    if (!ref.mounted) return null;
    state = CaptureState(
      step: CaptureStep.saving,
      roughM: fix != null && fix.accuracyM > 50 ? fix.accuracyM : null,
      noFix: fix == null,
    );
    final draft = await ref
        .read(reportsRepositoryProvider)
        .saveCapture(
          clientReportId: newId(),
          photoPath: path,
          lat: fix?.point.lat ?? 28.6440,
          lon: fix?.point.lon ?? 77.1900,
          accuracyM: fix?.accuracyM ?? 5000,
          coarse: fix == null || fix.coarse,
        );
    if (ref.mounted) state = const CaptureState();
    return draft.clientReportId;
  }
}

/// C5 draft.
@riverpod
Future<ReportDraft?> reportDraft(Ref ref, String clientReportId) =>
    ref.watch(reportsRepositoryProvider).draft(clientReportId);

/// C5 Send: queues `photo_upload` → `report_submit`; works offline.
@riverpod
class ReportSender extends _$ReportSender {
  @override
  bool build() => false;

  Future<void> send(
    String clientReportId, {
    required ReportCategory category,
    String? note,
    String? lang,
  }) async {
    state = true;
    try {
      await ref
          .read(reportsRepositoryProvider)
          .send(clientReportId, category: category, note: note, lang: lang);
    } finally {
      if (ref.mounted) state = false;
    }
  }
}
