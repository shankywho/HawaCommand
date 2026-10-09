import 'package:drift/drift.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/storage/tables/media_files_table.dart';

part 'media_dao.g.dart';

/// Media lifecycle: local → uploaded (object key known) or missing.
@DriftAccessor(tables: [MediaFilesTable])
class MediaDao extends DatabaseAccessor<AppDatabase> with _$MediaDaoMixin {
  MediaDao(super.attachedDatabase);

  Future<void> insertMedia(MediaFilesTableCompanion media) =>
      into(mediaFilesTable).insertOnConflictUpdate(media);

  Future<MediaFileRow?> getMedia(String id) =>
      (select(mediaFilesTable)..where((m) => m.id.equals(id))).getSingleOrNull();

  Future<List<MediaFileRow>> getMany(List<String> ids) =>
      (select(mediaFilesTable)..where((m) => m.id.isIn(ids))).get();

  Future<void> markUploaded(String id, String objectKey, DateTime at) =>
      (update(mediaFilesTable)..where((m) => m.id.equals(id))).write(
        MediaFilesTableCompanion(
          objectKey: Value(objectKey),
          state: const Value('uploaded'),
          uploadedAt: Value(at),
        ),
      );

  Future<void> markMissing(String id) => (update(
    mediaFilesTable,
  )..where((m) => m.id.equals(id))).write(const MediaFilesTableCompanion(state: Value('missing')));

  /// Uploaded files older than [before] whose full-size copy can be deleted (§6).
  Future<List<MediaFileRow>> uploadedBefore(DateTime before) => (select(
    mediaFilesTable,
  )..where((m) => m.state.equals('uploaded') & m.uploadedAt.isSmallerThanValue(before))).get();

  Future<void> deleteMedia(String id) =>
      (delete(mediaFilesTable)..where((m) => m.id.equals(id))).go();
}
