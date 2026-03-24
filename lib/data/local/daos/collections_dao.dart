import 'package:barcode_app/data/local/app_database.dart';
import 'package:barcode_app/data/local/tables/collections_table.dart';
import 'package:drift/drift.dart';

part 'collections_dao.g.dart';

@DriftAccessor(tables: [CollectionsTable])
class CollectionsDao extends DatabaseAccessor<AppDatabase> with _$CollectionsDaoMixin {
  CollectionsDao(super.db);

  Future<void> insertCollection(CollectionsTableCompanion entry) {
    return into(collectionsTable).insert(entry);
  }

  Future<List<CollectionsTableData>> listOpenCollections() {
    return (select(collectionsTable)..where((t) => t.status.equals('open'))).get();
  }
}
