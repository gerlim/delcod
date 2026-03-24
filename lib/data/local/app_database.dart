import 'package:barcode_app/data/local/tables/collections_table.dart';
import 'package:barcode_app/data/local/tables/companies_table.dart';
import 'package:barcode_app/data/local/tables/company_memberships_table.dart';
import 'package:barcode_app/data/local/tables/profiles_table.dart';
import 'package:barcode_app/data/local/tables/readings_table.dart';
import 'package:barcode_app/data/local/tables/sync_queue_table.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    CompaniesTable,
    ProfilesTable,
    CompanyMembershipsTable,
    CollectionsTable,
    ReadingsTable,
    SyncQueueTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}
