import 'package:barcode_app/features/readings/data/reading_item_json_mapper.dart';
import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/reading_classification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializa leitura identificada com o shape canonico', () {
    final item = ReadingItem(
      id: '1',
      code: 'BOB-123',
      source: 'camera',
      updatedAt: DateTime.parse('2026-03-30T12:00:00Z'),
      deletedAt: null,
      deviceId: 'device-a',
      codeType: 'paper_bobbin',
      classificationStatus: ReadingClassificationStatus.identified,
      classificationCandidates: const [],
      detailsPayload: const {
        'kind': 'bobbin',
      },
      metadataPayload: const {
        'batch': 'L-01',
        'weight': '14.6',
      },
      schemaVersion: 1,
    );

    expect(ReadingItemJsonMapper.toJson(item), {
      'id': '1',
      'code': 'BOB-123',
      'source': 'camera',
      'updated_at': '2026-03-30T12:00:00.000Z',
      'deleted_at': null,
      'device_id': 'device-a',
      'code_type': 'paper_bobbin',
      'classification_status': 'identified',
      'classification_candidates': <String>[],
      'details_payload': {
        'kind': 'bobbin',
      },
      'metadata_payload': {
        'batch': 'L-01',
        'weight': '14.6',
      },
      'schema_version': 1,
    });
  });

  test('serializa leitura ambigua com shape canonico por status', () {
    final item = ReadingItem(
      id: '2',
      code: 'MIX-123',
      source: 'import',
      updatedAt: DateTime.parse('2026-03-30T12:00:01Z'),
      deletedAt: null,
      deviceId: 'device-a',
      codeType: 'unknown',
      classificationStatus: ReadingClassificationStatus.ambiguous,
      classificationCandidates: const [
        'paper_bobbin',
        'paper_sheet',
      ],
      detailsPayload: null,
      schemaVersion: 1,
    );

    expect(ReadingItemJsonMapper.toJson(item)['code_type'], 'unknown');
    expect(
      ReadingItemJsonMapper.toJson(item)['classification_status'],
      'ambiguous',
    );
    expect(
        ReadingItemJsonMapper.toJson(item)['classification_candidates'], const [
      'paper_bobbin',
      'paper_sheet',
    ]);
    expect(ReadingItemJsonMapper.toJson(item)['details_payload'], isNull);
  });

  test('hidrata leituras antigas com defaults estruturais', () {
    final item = ReadingItemJsonMapper.fromJson(const {
      'id': 'legacy-1',
      'code': '7891234567890',
      'source': 'manual',
      'updated_at': '2026-03-30T12:00:00.000Z',
      'deleted_at': null,
      'device_id': 'legacy-device',
    });

    expect(item.codeType, 'unknown');
    expect(item.classificationStatus, ReadingClassificationStatus.unknown);
    expect(item.classificationCandidates, isEmpty);
    expect(item.detailsPayload, isNull);
    expect(item.metadataPayload, isNull);
    expect(item.schemaVersion, 1);
  });
}
