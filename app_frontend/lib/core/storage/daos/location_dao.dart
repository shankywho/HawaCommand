import 'package:drift/drift.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/storage/tables/location_pings_table.dart';

part 'location_dao.g.dart';

/// Shift-only location pings (ARCHITECTURE §11.3). Purged at shift end.
@DriftAccessor(tables: [LocationPingsTable])
class LocationDao extends DatabaseAccessor<AppDatabase> with _$LocationDaoMixin {
  LocationDao(super.attachedDatabase);

  Future<void> insertPing(LocationPingsTableCompanion ping) =>
      into(locationPingsTable).insert(ping);

  Future<List<LocationPingRow>> unbatched(String shiftLocalId) =>
      (select(locationPingsTable)
            ..where((p) => p.shiftLocalId.equals(shiftLocalId) & p.batched.equals(false))
            ..orderBy([(p) => OrderingTerm.asc(p.ts)]))
          .get();

  Future<void> markBatched(List<int> ids) => (update(
    locationPingsTable,
  )..where((p) => p.id.isIn(ids))).write(const LocationPingsTableCompanion(batched: Value(true)));

  Future<void> purgeShift(String shiftLocalId) =>
      (delete(locationPingsTable)..where((p) => p.shiftLocalId.equals(shiftLocalId))).go();

  Future<void> purgeAll() => delete(locationPingsTable).go();
}
