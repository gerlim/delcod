import 'package:drift/drift.dart';

class ReadingsTable extends Table {
  TextColumn get id => text()();
  TextColumn get collectionId => text()();
  TextColumn get code => text()();
  TextColumn get codeType => text().withDefault(const Constant('unknown'))();
  TextColumn get source => text()();
  TextColumn get createdBy => text()();
  BoolColumn get duplicateConfirmed =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
