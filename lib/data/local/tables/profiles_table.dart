import 'package:drift/drift.dart';

class ProfilesTable extends Table {
  TextColumn get id => text()();
  TextColumn get matricula => text()();
  TextColumn get name => text()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get lastLogin => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
