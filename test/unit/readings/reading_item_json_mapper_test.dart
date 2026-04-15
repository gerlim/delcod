import 'package:barcode_app/features/readings/data/reading_item_json_mapper.dart';
import 'package:barcode_app/features/readings/domain/reading_classification.dart';
import 'package:barcode_app/features/readings/domain/reading_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReadingItemJsonMapper', () {
    test('roundtrips classification and metadata', () {
      final item = ReadingItem(
        id: 'id-1',
        code: 'LOT-1',
        source: 'manual',
        updatedAt: DateTime.utc(2026, 4, 15, 12, 0, 0),
        deletedAt: null,
        deviceId: 'dev-1',
        classification: ReadingClassification.identified(
          'paper_bobbin',
          detailsPayload: const <String, dynamic>{'confidence': 'high'},
          schemaVersion: 2,
        ),
        metadataPayload: const <String, dynamic>{
          'bobbin_lot': 'LOT-1',
          'warehouse_code': '05',
        },
      );

      final encoded = ReadingItemJsonMapper.toJson(item);
      final decoded = ReadingItemJsonMapper.fromJson(encoded);

      expect(decoded.id, item.id);
      expect(decoded.code, item.code);
      expect(decoded.codeType, 'paper_bobbin');
      expect(
        decoded.classificationStatus,
        ReadingClassificationStatus.identified,
      );
      expect(decoded.schemaVersion, 2);
      expect(decoded.metadataPayload?['warehouse_code'], '05');
    });
  });
}
