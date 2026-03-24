import 'package:barcode_app/data/local/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expõe as tabelas centrais esperadas', () {
    final db = AppDatabase.forTesting();

    expect(db.allTables.length, greaterThanOrEqualTo(6));

    db.close();
  });
}
