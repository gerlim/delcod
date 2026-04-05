import 'package:barcode_app/features/readings/application/readings_list_filter.dart';
import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filtra por lote ou armazem', () {
    final items = <ReadingItem>[
      ReadingItem(
        id: '1',
        code: 'PPI-001',
        source: 'manual',
        updatedAt: DateTime.parse('2026-04-05T10:00:00.000Z'),
        deletedAt: null,
        deviceId: 'device-a',
        metadataPayload: const <String, dynamic>{
          'bobbin_lot': 'PPI-001',
          'warehouse_code': 'PPI',
          'warehouse_company': 'Bora Embalagens',
        },
      ),
      ReadingItem(
        id: '2',
        code: 'GLR-002',
        source: 'manual',
        updatedAt: DateTime.parse('2026-04-05T10:01:00.000Z'),
        deletedAt: null,
        deviceId: 'device-b',
        metadataPayload: const <String, dynamic>{
          'bobbin_lot': 'GLR-002',
          'warehouse_code': 'GLR',
          'warehouse_company': 'ABN Embalagens',
        },
      ),
    ];

    expect(
      ReadingsListFilter.apply(items, 'ppi').map((item) => item.id),
      ['1'],
    );
    expect(
      ReadingsListFilter.apply(items, 'glr').map((item) => item.id),
      ['2'],
    );
  });

  test('retorna tudo quando a busca estiver vazia', () {
    final items = <ReadingItem>[
      ReadingItem(
        id: '1',
        code: 'LOT-01',
        source: 'manual',
        updatedAt: DateTime.parse('2026-04-05T10:00:00.000Z'),
        deletedAt: null,
        deviceId: 'device-a',
      ),
    ];

    expect(ReadingsListFilter.apply(items, '   '), same(items));
  });
}
