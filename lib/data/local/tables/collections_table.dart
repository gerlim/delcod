import 'package:drift/drift.dart';

class CollectionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get companyId => text()();
  TextColumn get title => text()();
  TextColumn get status => text().withDefault(const Constant('open'))();
  TextColumn get createdBy => text()();
  DateTimeColumn get openedAt => dateTime()();
  DateTimeColumn get closedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
