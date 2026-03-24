import 'package:drift/drift.dart';

class CompanyMembershipsTable extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text()();
  TextColumn get profileId => text()();
  TextColumn get role => text()();
  TextColumn get status => text().withDefault(const Constant('active'))();

  @override
  Set<Column> get primaryKey => {id};
}
