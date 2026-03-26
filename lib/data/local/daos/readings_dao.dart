import 'package:barcode_app/data/local/app_database.dart';
import 'package:barcode_app/data/local/tables/readings_table.dart';
import 'package:drift/drift.dart';

part 'readings_dao.g.dart';

@DriftAccessor(tables: [ReadingsTable])
class ReadingsDao extends DatabaseAccessor<AppDatabase>
    with _$ReadingsDaoMixin {
  ReadingsDao(super.db);

  Future<void> insertReading(ReadingsTableCompanion entry) {
    return into(readingsTable).insert(entry);
  }

  Future<List<ReadingsTableData>> listByCollection(String collectionId) {
    return (select(readingsTable)
          ..where((t) => t.collectionId.equals(collectionId)))
        .get();
  }
}
