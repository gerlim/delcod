import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/bobbin_inventory_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deriva empresa Bora Embalagens para armazens 05 e PPI', () {
    final lotFrom05 = BobbinInventoryRecord.fromItem(
      ReadingItem(
        id: '1',
        code: '001126023205936309',
        source: 'camera',
        updatedAt: DateTime.parse('2026-03-31T12:00:00Z'),
        deletedAt: null,
        deviceId: 'device-a',
        metadataPayload: const {
          'warehouse_code': '05',
        },
      ),
    );
    final lotFromPpi = BobbinInventoryRecord.fromItem(
      ReadingItem(
        id: '2',
        code: '001125816205936325',
        source: 'camera',
        updatedAt: DateTime.parse('2026-03-31T12:00:00Z'),
        deletedAt: null,
        deviceId: 'device-a',
        metadataPayload: const {
          'warehouse_code': 'PPI',
        },
      ),
    );

    expect(lotFrom05.lot, '001126023205936309');
    expect(lotFrom05.warehouseCode, '05');
    expect(lotFrom05.companyName, 'Bora Embalagens');
    expect(lotFromPpi.companyName, 'Bora Embalagens');
  });

  test('marca leitura pendente quando o armazem nao foi informado', () {
    final record = BobbinInventoryRecord.fromItem(
      ReadingItem(
        id: '3',
        code: '161358205936907',
        source: 'import',
        updatedAt: DateTime.parse('2026-03-31T12:00:00Z'),
        deletedAt: null,
        deviceId: 'device-a',
      ),
    );

    expect(record.lot, '161358205936907');
    expect(record.warehouseCode, isNull);
    expect(record.companyName, isNull);
    expect(record.hasWarehouseAllocated, isFalse);
    expect(record.statusLabel, 'Sem armazem alocado');
  });
}
