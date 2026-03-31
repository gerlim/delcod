import 'dart:async';

import 'package:barcode_app/features/readings/application/readings_controller.dart';
import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/reading_classification.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('salva leitura com armazem e empresa derivada no metadata payload', () async {
    final repository = _WarehouseFakeReadingsRepository();
    final container = ProviderContainer(
      overrides: [
        readingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(readingsControllerProvider.future);

    await container.read(readingsControllerProvider.notifier).addCode(
          '001126023205936309',
          source: 'camera',
          warehouseCode: '05',
        );

    final items = await container.read(readingsControllerProvider.future);
    final saved = items.single;
    expect(saved.metadataPayload?['bobbin_lot'], '001126023205936309');
    expect(saved.metadataPayload?['warehouse_code'], '05');
    expect(saved.metadataPayload?['warehouse_company'], 'Bora Embalagens');
  });
}

class _WarehouseFakeReadingsRepository implements ReadingsRepository {
  final List<ReadingItem> _items = [];
  final StreamController<List<ReadingItem>> _controller =
      StreamController<List<ReadingItem>>.broadcast();

  @override
  Future<ReadingItem> addCode({
    required String code,
    required String source,
    ReadingClassification? classification,
    Map<String, dynamic>? metadataPayload,
  }) async {
    final created = ReadingItem(
      id: 'generated-1',
      code: code,
      source: source,
      updatedAt: DateTime.parse('2026-03-31T12:00:00Z'),
      deletedAt: null,
      deviceId: 'device-a',
      classification: classification,
      metadataPayload: metadataPayload,
    );
    _items.add(created);
    _controller.add(List<ReadingItem>.from(_items));
    return created;
  }

  @override
  Future<List<ReadingItem>> addCodesBatch({
    required List<String> codes,
    required String source,
    List<ReadingClassification>? classifications,
    List<Map<String, dynamic>?>? metadataPayloads,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> checkOnlineStatus() async => true;

  @override
  Future<void> clearAll() async {}

  @override
  void dispose() {
    _controller.close();
  }

  @override
  Future<bool> existsCode(String code, {String? excludingId}) async => false;

  @override
  Future<List<ReadingItem>> fetchActive() async => List<ReadingItem>.from(_items);

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<void> syncNow() async {}

  @override
  Future<void> updateCode({
    required String id,
    required String newCode,
    ReadingClassification? classification,
    Map<String, dynamic>? metadataPayload,
  }) async {}

  @override
  Stream<List<ReadingItem>> watchActive() => _controller.stream;

  @override
  Stream<bool> watchOnlineStatus() => const Stream<bool>.empty();
}
