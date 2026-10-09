import 'package:drift/drift.dart';

/// Local photos before and after upload (OFFLINE_AND_SYNC §3, §6).
@DataClassName('MediaFileRow')
class MediaFilesTable extends Table {
  @override
  String get tableName => 'media_files';

  TextColumn get id => text()();
  TextColumn get path => text()();
  TextColumn get sha256 => text()();
  IntColumn get bytes => integer()();
  TextColumn get purpose => text()(); // UploadPurpose
  TextColumn get objectKey => text().nullable()();
  TextColumn get state => text()(); // local | uploaded | missing
  TextColumn get thumbPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get uploadedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
