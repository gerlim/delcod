import 'dart:async';

import 'package:barcode_app/features/readings/application/readings_controller.dart';
import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/bobbin_inventory_record.dart';
import 'package:barcode_app/features/readings/domain/duplicate_decision.dart';
import 'package:barcode_app/features/readings/domain/reading_classification.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('avisa duplicidade e permite salvar quando confirmado', () async {
    final repository = _FakeReadingsRepository(
      seeded: [
        _item(
          id: 'a',
          code: '7891234567890',
          source: 'camera',
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        readingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(readingsControllerProvider.future);

    final warning =
        await container.read(readingsControllerProvider.notifier).addCode(
              '7891234567890',
              source: 'camera',
            );

    final saved =
        await container.read(readingsControllerProvider.notifier).addCode(
              '7891234567890',
              source: 'camera',
              forceDuplicate: true,
            );

    final items = await container.read(readingsControllerProvider.future);

    expect(warning, DuplicateDecision.warning);
    expect(saved, DuplicateDecision.saved);
    expect(items, hasLength(2));
    expect(
      items.any(
        (item) =>
            item.code == '7891234567890' && item.codeType == 'paper_bobbin',
      ),
      isTrue,
    );
  });

  test('edita, exclui e limpa todos os codigos ativos', () async {
    final repository = _FakeReadingsRepository(
      seeded: [
        _item(id: 'a', code: '11111111', source: 'camera'),
        _item(id: 'b', code: '22222222', source: 'manual'),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        readingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(readingsControllerProvider.future);
    final notifier = container.read(readingsControllerProvider.notifier);

    await notifier.updateCode(
      id: 'a',
      newCode: '33333333',
    );
    await notifier.deleteCode('b');

    var items = await container.read(readingsControllerProvider.future);
    expect(items.map((item) => item.code), ['33333333']);
    expect(items.single.codeType, 'paper_bobbin');

    await notifier.clearAll();
    items = await container.read(readingsControllerProvider.future);
    expect(items, isEmpty);
  });

  test('reprocessa classificacao preservando metadados existentes', () async {
    final repository = _FakeReadingsRepository(
      seeded: [
        ReadingItem(
          id: 'legacy',
          code: '7891234567890',
          source: 'import',
          updatedAt: DateTime(2026, 3, 25, 10),
          deletedAt: null,
          deviceId: 'device-a',
          metadataPayload: const {
            'batch': 'L-01',
          },
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        readingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(readingsControllerProvider.future);
    final notifier = container.read(readingsControllerProvider.notifier);

    await notifier.reprocessClassifications();

    final items = await container.read(readingsControllerProvider.future);
    expect(items.single.codeType, 'paper_bobbin');
    expect(items.single.metadataPayload, const {
      'batch': 'L-01',
    });
  });

  test('aloca armazem em lote apenas para leituras pendentes quando nao reescreve', () async {
    final repository = _FakeReadingsRepository(
      seeded: [
        ReadingItem(
          id: 'pending',
          code: '001126023205936309',
          source: 'camera',
          updatedAt: DateTime(2026, 3, 25, 10),
          deletedAt: null,
          deviceId: 'device-a',
        ),
        ReadingItem(
          id: 'allocated',
          code: '001125816205936325',
          source: 'camera',
          updatedAt: DateTime(2026, 3, 25, 10),
          deletedAt: null,
          deviceId: 'device-a',
          metadataPayload: const {
            'bobbin_lot': '001125816205936325',
            'warehouse_code': 'GLR',
            'warehouse_company': 'ABN Embalagens',
          },
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        readingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(readingsControllerProvider.future);

    final result = await container
        .read(readingsControllerProvider.notifier)
        .allocateWarehouse(
          itemIds: const ['pending', 'allocated'],
          warehouseCode: '05',
          overwriteExisting: false,
        );

    final items = await container.read(readingsControllerProvider.future);
    final pendingItem = items.firstWhere((item) => item.id == 'pending');
    final allocatedItem = items.firstWhere((item) => item.id == 'allocated');

    expect(result.updatedCount, 1);
    expect(result.overwrittenCount, 0);
    expect(
      BobbinInventoryRecord.fromItem(pendingItem).companyName,
      'Bora Embalagens',
    );
    expect(
      BobbinInventoryRecord.fromItem(allocatedItem).warehouseCode,
      'GLR',
    );
  });

  test('aloca armazem em lote reescrevendo leituras ja alocadas quando confirmado', () async {
    final repository = _FakeReadingsRepository(
      seeded: [
        ReadingItem(
          id: 'pending',
          code: '001126023205936309',
          source: 'camera',
          updatedAt: DateTime(2026, 3, 25, 10),
          deletedAt: null,
          deviceId: 'device-a',
        ),
        ReadingItem(
          id: 'allocated',
          code: '001125816205936325',
          source: 'camera',
          updatedAt: DateTime(2026, 3, 25, 10),
          deletedAt: null,
          deviceId: 'device-a',
          metadataPayload: const {
            'bobbin_lot': '001125816205936325',
            'warehouse_code': 'GLR',
            'warehouse_company': 'ABN Embalagens',
          },
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        readingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(readingsControllerProvider.future);

    final result = await container
        .read(readingsControllerProvider.notifier)
        .allocateWarehouse(
          itemIds: const ['pending', 'allocated'],
          warehouseCode: '05',
          overwriteExisting: true,
        );

    final items = await container.read(readingsControllerProvider.future);

    expect(result.updatedCount, 2);
    expect(result.overwrittenCount, 1);
    expect(
      items
          .map(BobbinInventoryRecord.fromItem)
          .every((record) => record.warehouseCode == '05'),
      isTrue,
    );
  });
}

ReadingItem _item({
  required String id,
  required String code,
  required String source,
}) {
  return ReadingItem(
    id: id,
    code: code,
    source: source,
    updatedAt: DateTime(2026, 3, 25, 10),
    deletedAt: null,
    deviceId: 'device-a',
  );
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
      updatedAt: DateTime(2026, 3, 25, 10),
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
      final code = codes[index];
      final item = ReadingItem(
        id: 'generated-${_items.length + 1}',
        code: code,
        source: source,
        updatedAt: DateTime(2026, 3, 25, 10),
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
      updatedAt: DateTime(2026, 3, 25, 11),
      classification: classification,
      metadataPayload: metadataPayload,
    );
    _emit();
  }

  @override
  Future<void> softDelete(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    _items[index] = _items[index].copyWith(
      deletedAt: DateTime(2026, 3, 25, 12),
    );
    _emit();
  }

  @override
  Future<void> clearAll() async {
    for (var index = 0; index < _items.length; index++) {
      _items[index] = _items[index].copyWith(
        deletedAt: DateTime(2026, 3, 25, 13),
      );
    }
    _emit();
  }

  List<ReadingItem> _activeItems() {
    final active = _items.where((item) => item.deletedAt == null).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return active;
  }

  void _emit() {
    _controller.add(_activeItems());
  }

  @override
  Future<bool> checkOnlineStatus() async => true;

  @override
  void dispose() {
    _controller.close();
  }

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<void> syncNow() async {}

  @override
  Stream<bool> watchOnlineStatus() => const Stream<bool>.empty();
}
