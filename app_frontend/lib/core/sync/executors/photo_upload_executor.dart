import 'dart:io';

import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/media/upload_service.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/sync/executors/op_executor.dart';
import 'package:hawa_app/core/sync/outbox_op.dart';
import 'package:hawa_app/core/utils/clock.dart';

/// Presign + S3 presigned POST for one local photo. Stores the object key in `media_files`
/// (dependent ops read it at execution time).
class PhotoUploadExecutor extends OpExecutor {
  PhotoUploadExecutor(this.db, this.uploads, this.clock, {this.recompress, this.onProgress});

  final AppDatabase db;
  final UploadService uploads;
  final Clock clock;

  /// 413 → retry once after re-compressing at 1280 px q70 (OFFLINE_AND_SYNC §5.5).
  final Future<File?> Function(File original)? recompress;
  final void Function(String mediaId, double progress)? onProgress;

  @override
  OpKind get kind => OpKind.photoUpload;

  @override
  Future<Map<String, Object?>?> execute(OutboxOp op) async {
    final mediaId = op.payload['media_id']! as String;
    final media = await db.mediaDao.getMedia(mediaId);
    if (media == null) throw const ValidationFailure([], code: 'media_missing');
    if (media.objectKey != null) return {'object_key': media.objectKey};
    final file = File(media.path);
    if (!file.existsSync()) {
      await db.mediaDao.markMissing(mediaId);
      throw const ValidationFailure([], code: 'media_missing');
    }
    String key;
    try {
      key = await _upload(file, media.purpose, media.sha256, mediaId);
    } on ValidationFailure catch (e) {
      final smaller = e.status == 413 ? await recompress?.call(file) : null;
      if (smaller == null) rethrow;
      key = await _upload(smaller, media.purpose, media.sha256, mediaId);
    }
    await db.mediaDao.markUploaded(mediaId, key, clock.now().toUtc());
    return {'object_key': key};
  }

  Future<String> _upload(File file, String purpose, String sha, String mediaId) => uploads.upload(
    file: file,
    purpose: purpose,
    sha256: sha,
    onProgress: (sent, total) => onProgress?.call(mediaId, total == 0 ? 0 : sent / total),
  );
}
