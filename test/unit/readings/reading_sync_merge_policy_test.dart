import 'package:barcode_app/features/readings/data/reading_sync_merge_policy.dart';
import 'package:barcode_app/features/readings/domain/reading_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReadingSyncMergePolicy', () {
    test(
      'prefere o remoto quando nao existe mutacao pendente mesmo se o cache local tiver timestamp maior',
      () {
        final local = ReadingItem(
          id: '1',
          code: 'LOT-1',
          source: 'camera',
          updatedAt: DateTime.utc(2026, 4, 15, 22, 0, 0),
          deletedAt: null,
          deviceId: 'device-a',
        );
        final remote = ReadingItem(
          id: '1',
          code: 'LOT-1',
          source: 'camera',
          updatedAt: DateTime.utc(2026, 4, 15, 21, 0, 0),
          deletedAt: DateTime.utc(2026, 4, 15, 21, 0, 0),
          deviceId: 'device-b',
        );

        final merged = ReadingSyncMergePolicy.resolve(
          current: local,
          remote: remote,
          hasPendingMutation: false,
        );

        expect(merged.deletedAt, remote.deletedAt);
        expect(merged.deviceId, remote.deviceId);
      },
    );

    test('mantem o local enquanto existir mutacao pendente para o item', () {
      final local = ReadingItem(
        id: '1',
        code: 'LOT-1',
        source: 'camera',
        updatedAt: DateTime.utc(2026, 4, 15, 22, 0, 0),
        deletedAt: null,
        deviceId: 'device-a',
      );
      final remote = ReadingItem(
        id: '1',
        code: 'LOT-1',
        source: 'camera',
        updatedAt: DateTime.utc(2026, 4, 15, 21, 0, 0),
        deletedAt: DateTime.utc(2026, 4, 15, 21, 0, 0),
        deviceId: 'device-b',
      );

      final merged = ReadingSyncMergePolicy.resolve(
        current: local,
        remote: remote,
        hasPendingMutation: true,
      );

      expect(merged.deletedAt, isNull);
      expect(merged.deviceId, 'device-a');
    });
  });
}
