import 'dart:async';

import 'package:barcode_app/features/readings/application/readings_controller.dart';
import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('importa somente novos ou todo o lote conforme a escolha', () async {
    final repository = _FakeReadingsRepository(
      seeded: [
        _item(id: 'a', code: '111', source: 'manual'),
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

    final importOnlyNew = await notifier.importCodes(
      ['111', '222', '222', '333'],
      includeDuplicates: false,
    );

    expect(importOnlyNew.importedCount, 2);
    expect(importOnlyNew.skippedDuplicates, 2);

    final importAll = await notifier.importCodes(
      ['444', '444'],
      includeDuplicates: true,
    );

    expect(importAll.importedCount, 2);
    expect(importAll.skippedDuplicates, 0);

    final items = await container.read(readingsControllerProvider.future);
    expect(items.map((item) => item.code), ['444', '444', '333', '222', '111']);
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
  }) async {
    final created = ReadingItem(
      id: 'generated-${_items.length + 1}',
      code: code,
      source: source,
      updatedAt: DateTime(2026, 3, 25, 10),
      deletedAt: null,
      deviceId: 'device-a',
    );
    _items.add(created);
    _emit();
    return created;
  }

  @override
  Future<List<ReadingItem>> addCodesBatch({
    required List<String> codes,
    required String source,
  }) async {
    final created = <ReadingItem>[];
    for (final code in codes) {
      final item = ReadingItem(
        id: 'generated-${_items.length + 1}',
        code: code,
        source: source,
        updatedAt: DateTime(2026, 3, 25, 10, 0, _items.length + 1),
        deletedAt: null,
        deviceId: 'device-a',
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
  }) async {
    final index = _items.indexWhere((item) => item.id == id);
    _items[index] = _items[index].copyWith(
      code: newCode,
      updatedAt: DateTime(2026, 3, 25, 11),
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
