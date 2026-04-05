import 'package:barcode_app/features/readings/application/readings_export_payload_builder.dart';
import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('monta payload de exportacao a partir das leituras', () {
    const builder = ReadingsExportPayloadBuilder();
    final payload = builder.build(
      title: 'DelCod',
      items: [
        ReadingItem(
          id: '1',
          code: 'LOT-01',
          source: 'manual',
          updatedAt: DateTime.parse('2026-04-05T10:00:00.000Z'),
          deletedAt: null,
          deviceId: 'device-a',
          metadataPayload: const <String, dynamic>{
            'bobbin_lot': 'LOT-01',
            'warehouse_code': '05',
            'warehouse_company': 'Bora Embalagens',
          },
        ),
      ],
    );

    expect(payload.title, 'DelCod');
    expect(payload.rows, hasLength(1));
    expect(payload.rows.single.lot, 'LOT-01');
    expect(payload.rows.single.warehouseCode, '05');
    expect(payload.rows.single.companyName, 'Bora Embalagens');
    expect(payload.rows.single.isPendingWarehouse, isFalse);
  });
}
