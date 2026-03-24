import 'package:barcode_app/data/local/app_database.dart';
import 'package:barcode_app/data/local/daos/readings_dao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('insere uma leitura e lista de volta pela coleta', () async {
    final db = AppDatabase.forTesting();
    final dao = ReadingsDao(db);

    await dao.insertReading(
      ReadingsTableCompanion.insert(
        id: 'reading-1',
        collectionId: 'collection-1',
        code: '7891234567890',
        source: 'camera',
        createdBy: 'operator-1',
        createdAt: DateTime(2026, 3, 23, 20, 0),
      ),
    );

    final rows = await dao.listByCollection('collection-1');

    expect(rows, hasLength(1));
    expect(rows.single.code, '7891234567890');

    await db.close();
  });
}
