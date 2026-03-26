import 'package:barcode_app/data/local/app_database.dart';
import 'package:barcode_app/data/local/tables/sync_queue_table.dart';
import 'package:drift/drift.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueueTable])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  Future<void> enqueue(SyncQueueTableCompanion entry) {
    return into(syncQueueTable).insert(entry);
  }

  Future<List<SyncQueueTableData>> listPending() {
    return (select(syncQueueTable)..where((t) => t.status.equals('pending')))
        .get();
  }

  Future<bool> markCompleted(String id) {
    return (update(syncQueueTable)..where((t) => t.id.equals(id))).write(
      const SyncQueueTableCompanion(status: Value('completed')),
    );
  }

  Future<bool> markFailed(String id, String message) {
    return (update(syncQueueTable)..where((t) => t.id.equals(id))).write(
      SyncQueueTableCompanion(
        status: const Value('failed'),
        lastError: Value(message),
        attempts: const Value(1),
      ),
    );
  }
}
