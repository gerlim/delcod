import 'dart:async';

import 'package:barcode_app/features/import/data/reading_import_service.dart';
import 'package:barcode_app/features/readings/application/inventory_reconciliation_provider.dart';
import 'package:barcode_app/features/readings/application/readings_controller.dart';
import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/inventory_reconciliation.dart';
import 'package:barcode_app/features/readings/domain/reading_classification.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('construi snapshot de conciliacao a partir de importacao e leitura real', () async {
    final repository = _FakeReadingsRepository();
    final container = ProviderContainer(
      overrides: [
        readingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(readingsControllerProvider.future);
    final notifier = container.read(readingsControllerProvider.notifier);

    await notifier.importReadings(
      const [
        ImportedReadingEntry(
          code: '001126023205936309',
          metadata: {
            'warehouse_code': '05',
          },
        ),
      ],
      includeDuplicates: false,
    );
    await notifier.addCode(
      '001126023205936309',
      source: 'camera',
      warehouseCode: 'GLR',
      forceDuplicate: true,
    );
    await notifier.addCode(
      '001125816205936325',
      source: 'manual',
      warehouseCode: 'PPI',
    );

    final snapshot = container.read(inventoryReconciliationSnapshotProvider);

    final matched = snapshot.byLot['001126023205936309'];
    final unexpected = snapshot.byLot['001125816205936325'];

    expect(matched, isNotNull);
    expect(
      matched!.presenceStatus,
      InventoryPresenceStatus.matched,
    );
    expect(
      matched.warehouseStatus,
      InventoryWarehouseStatus.mismatch,
    );

    expect(unexpected, isNotNull);
    expect(
      unexpected!.presenceStatus,
      InventoryPresenceStatus.countedOnly,
    );
    expect(snapshot.warehouseMismatchLotsCount, 1);
    expect(snapshot.unexpectedLotsCount, 1);
  });
}

class _FakeReadingsRepository implements ReadingsRepository {
  _FakeReadingsRepository({
    List<ReadingItem> seeded = const [],
  }) : _items = List.of(seeded) {
    _controller.add(_activeItems());
  }

  final List<ReadingItem> _items;
  final StreamController<List<ReadingItem>> _controller =
      StreamController<List<ReadingItem>>.broadcast();

  @override
  Stream<List<ReadingItem>> watchActive() => _controller.stream;

  @override
  Future<List<ReadingItem>> fetchActive() async => _activeItems();

  @override
  Future<bool> existsCode(
    String code, {
    String? excludingId,
  }) async {
    return _items.any(
      (item) =>
          item.deletedAt == null && item.code == code && item.id != excludingId,
    );
  }

  @override
  Future<ReadingItem> addCode({
    required String code,
    required String source,
    ReadingClassification? classification,
    Map<String, dynamic>? metadataPayload,
  }) async {
    final created = ReadingItem(
      id: 'generated-${_items.length + 1}',
      code: code,
      source: source,
      updatedAt: DateTime(2026, 4, 1, 10, 0, _items.length + 1),
      deletedAt: null,
      deviceId: 'device-a',
      classification: classification,
      metadataPayload: metadataPayload,
    );
    _items.add(created);
    _emit();
    return created;
  }

  @override
  Future<List<ReadingItem>> addCodesBatch({
    required List<String> codes,
    required String source,
    List<ReadingClassification>? classifications,
    List<Map<String, dynamic>?>? metadataPayloads,
  }) async {
    final created = <ReadingItem>[];
    for (var index = 0; index < codes.length; index++) {
      final item = ReadingItem(
        id: 'generated-${_items.length + 1}',
        code: codes[index],
        source: source,
        updatedAt: DateTime(2026, 4, 1, 10, 1, _items.length + 1),
        deletedAt: null,
        deviceId: 'device-a',
        classification:
            index < (classifications?.length ?? 0) ? classifications![index] : null,
        metadataPayload:
            index < (metadataPayloads?.length ?? 0) ? metadataPayloads![index] : null,
      );
      _items.add(item);
      created.add(item);
    }
    _emit();
    return created;
  }

  @override
  Future<void> updateCode({
    required String id,
    required String newCode,
    ReadingClassification? classification,
    Map<String, dynamic>? metadataPayload,
  }) async {
    final index = _items.indexWhere((item) => item.id == id);
    _items[index] = _items[index].copyWith(
      code: newCode,
      updatedAt: DateTime(2026, 4, 1, 11),
      classification: classification,
      metadataPayload: metadataPayload,
    );
    _emit();
  }

  @override
  Future<void> softDelete(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    _items[index] = _items[index].copyWith(
      deletedAt: DateTime(2026, 4, 1, 12),
    );
    _emit();
  }

  @override
  Future<void> clearAll() async {
    for (var index = 0; index < _items.length; index++) {
      _items[index] = _items[index].copyWith(
        deletedAt: DateTime(2026, 4, 1, 13),
      );
    }
    _emit();
  }

  @override
  Future<bool> checkOnlineStatus() async => true;

  @override
  Stream<bool> watchOnlineStatus() => const Stream<bool>.empty();

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<void> syncNow() async {}

  @override
  void dispose() {
    _controller.close();
  }

  List<ReadingItem> _activeItems() {
    final active = _items.where((item) => item.deletedAt == null).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return active;
  }

  void _emit() {
    _controller.add(_activeItems());
  }
}
