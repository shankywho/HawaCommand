import 'package:drift/drift.dart' show Value;
import 'package:hawa_app/core/media/image_processor.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:hawa_app/core/sync/outbox_op.dart';
import 'package:hawa_app/core/sync/outbox_repository.dart';
import 'package:hawa_app/core/utils/clock.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/localized_text.dart';
import 'package:hawa_app/core/utils/streams.dart';
import 'package:hawa_app/features/citizen_reports/data/reports_remote_source.dart';
import 'package:hawa_app/features/citizen_reports/domain/citizen_report.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reports_repository_impl.g.dart';

/// C4–C7: drafts in `reports_draft` (+ `media_files`), sends through the outbox, and the server
/// list cached in `cached_payloads` merged with unsent drafts.
class ReportsRepository {
  ReportsRepository({
    required this.db,
    required this.remote,
    required this.outbox,
    required this.images,
    required this.settings,
    required this.now,
  });

  final AppDatabase db;
  final ReportsRemoteSource remote;
  final OutboxRepository outbox;
  final ImageProcessor images;
  final SettingsStore settings;
  final DateTime Function() now;

  static const mineKey = 'reports:mine';
  static String detailKey(String id) => 'reports:detail:$id';

  /// C6 rows: unsent drafts first, then the server list (deduped by client id).
  Stream<List<ReportListItem>> watchMine() => combineLatest2(
    db.reportDao.watchAll(),
    db.cacheDao.watchJson(mineKey),
    (drafts, cached) {
      final server = cached == null ? <ReportListItem>[] : listFromJson(cached.json);
      final serverKeys = {for (final s in server) s.key};
      final waiting = [
        for (final d in drafts)
          if (d.state != 'draft' &&
              d.state != 'submitted' &&
              !serverKeys.contains(d.clientReportId))
            ReportListItem(
              key: d.clientReportId,
              createdAt: d.createdAt,
              status: ReportStatus.submitted,
              note: d.note,
              waiting: true,
            ),
      ];
      return [...waiting, ...server]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    },
  );

  Future<void> refreshMine() async {
    final json = await remote.mine();
    await db.cacheDao.putJson(mineKey, json, fetchedAt: now().toUtc());
  }

  Stream<ReportDetail?> watchDetail(String id) =>
      db.cacheDao.watchJson(detailKey(id)).map((c) => c == null ? null : detailFromJson(c.json));

  Future<void> refreshDetail(String id) async {
    final json = await remote.get(id);
    await db.cacheDao.putJson(detailKey(id), json, fetchedAt: now().toUtc());
  }

  /// C4 → C5: strips EXIF/resizes, stores the photo and a draft row.
  Future<ReportDraft> saveCapture({
    required String clientReportId,
    required String photoPath,
    required double lat,
    required double lon,
    required double accuracyM,
    required bool coarse,
  }) async {
    final processed = await images.process(photoPath, dataSaver: settings.dataSaver);
    final t = now().toUtc();
    await db.mediaDao.insertMedia(
      MediaFilesTableCompanion.insert(
        id: processed.id,
        path: processed.file.path,
        sha256: processed.sha256,
        bytes: processed.bytes,
        purpose: 'report_photo',
        state: 'local',
        createdAt: t,
        thumbPath: Value(processed.thumb?.path),
      ),
    );
    await db.reportDao.upsertDraft(
      ReportsDraftTableCompanion.insert(
        clientReportId: clientReportId,
        mediaIdsJson: '["${processed.id}"]',
        lat: lat,
        lon: lon,
        accuracyM: accuracyM,
        locationQuality: coarse ? 'coarse' : 'precise',
        capturedAt: t,
        category: ReportCategory.burning.wire,
        state: 'draft',
        createdAt: t,
      ),
    );
    return ReportDraft(
      clientReportId: clientReportId,
      photoPath: processed.file.path,
      lat: lat,
      lon: lon,
      accuracyM: accuracyM,
      capturedAt: t,
      coarse: coarse,
    );
  }

  Future<ReportDraft?> draft(String clientReportId) async {
    final d = await db.reportDao.getDraft(clientReportId);
    if (d == null) return null;
    final mediaId = d.mediaIdsJson.replaceAll(RegExp(r'[\[\]"]'), '').split(',').first;
    final media = await db.mediaDao.getMedia(mediaId);
    return ReportDraft(
      clientReportId: d.clientReportId,
      photoPath: media?.path ?? '',
      lat: d.lat,
      lon: d.lon,
      accuracyM: d.accuracyM,
      capturedAt: d.capturedAt,
      coarse: d.locationQuality == 'coarse',
    );
  }

  /// C5 Send: `photo_upload` then `report_submit` (dependsOn), in one transaction. One report per
  /// Send even with retries (`client_report_id` is the natural key).
  Future<void> send(
    String clientReportId, {
    required ReportCategory category,
    String? note,
    String? lang,
  }) async {
    final d = await db.reportDao.getDraft(clientReportId);
    if (d == null || d.state != 'draft') return;
    final mediaId = d.mediaIdsJson.replaceAll(RegExp(r'[\[\]"]'), '').split(',').first;
    await db.transaction(() async {
      final photoOp = await outbox.enqueue(
        kind: OpKind.photoUpload,
        orderingKey: OrderingKeys.media(mediaId),
        payload: {'media_id': mediaId},
      );
      await outbox.enqueue(
        kind: OpKind.reportSubmit,
        orderingKey: OrderingKeys.report(clientReportId),
        dependsOn: photoOp,
        payload: {
          'client_report_id': clientReportId,
          'media_id': mediaId,
          'lat': d.lat,
          'lon': d.lon,
          'accuracy_m': d.accuracyM,
          'captured_at': d.capturedAt.toUtc().toIso8601String(),
          'category': category.wire,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
          'lang': ?lang,
        },
      );
      await db.reportDao.upsertDraft(
        ReportsDraftTableCompanion(
          clientReportId: Value(clientReportId),
          mediaIdsJson: Value(d.mediaIdsJson),
          lat: Value(d.lat),
          lon: Value(d.lon),
          accuracyM: Value(d.accuracyM),
          locationQuality: Value(d.locationQuality),
          capturedAt: Value(d.capturedAt),
          category: Value(category.wire),
          note: Value(note),
          state: const Value('queued'),
          createdAt: Value(d.createdAt),
        ),
      );
    });
  }

  // ---- mapping (pure) ---------------------------------------------------------------------

  static LocalizedText? _text(Object? v) =>
      v is Map<String, Object?> && v['en'] is String ? LocalizedText.fromJson(v) : null;

  static DateTime _date(Object? v) =>
      DateTime.tryParse(v as String? ?? '')?.toUtc() ?? DateTime.now().toUtc();

  static List<ReportListItem> listFromJson(Map<String, Object?> json) => [
    for (final r in (json['items'] as List<Object?>?) ?? const [])
      if (r is Map<String, Object?>)
        ReportListItem(
          key: r['client_report_id'] as String? ?? r['id']! as String,
          serverId: r['id'] as String?,
          createdAt: _date(r['created_at']),
          status: ReportStatus.fromWire(r['status'] as String?),
          placeName: _text(r['place_name']),
          note: r['note'] as String?,
          thumbnail: r['thumbnail_url'] as String?,
          viaWhatsapp: r['source'] == 'whatsapp',
          isSimulated: r['is_simulated'] as bool? ?? false,
        ),
  ];

  static ReportDetail detailFromJson(Map<String, Object?> j) {
    LocalizedText? pair(String en, String hi) =>
        j[en] is String ? LocalizedText(en: j[en]! as String, hi: j[hi] as String?) : null;
    return ReportDetail(
      id: j['id']! as String,
      createdAt: _date(j['created_at']),
      status: ReportStatus.fromWire(j['status'] as String?),
      placeName: _text(j['place_name']),
      photo: j['photo_url'] as String?,
      timeline: [
        for (final t in (j['timeline'] as List<Object?>?) ?? const [])
          if (t is Map<String, Object?>)
            TimelineEntry(
              status: ReportStatus.fromWire(t['status'] as String?),
              at: _date(t['at']),
            ),
      ],
      outcome: j['outcome'] as String?,
      outcomeText: pair('outcome_text', 'outcome_text_hi'),
      rejectionReason: pair('rejection_reason', 'rejection_reason_hi'),
      isSimulated: j['is_simulated'] as bool? ?? false,
    );
  }
}

@riverpod
ReportsRepository reportsRepository(Ref ref) => ReportsRepository(
  db: ref.watch(appDatabaseProvider),
  remote: ref.watch(reportsRemoteSourceProvider),
  outbox: ref.watch(outboxRepositoryProvider),
  images: ref.watch(imageProcessorProvider),
  settings: ref.watch(settingsStoreProvider),
  now: ref.watch(appClockProvider).now,
);
