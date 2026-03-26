import 'dart:async';

import 'package:barcode_app/features/readings/application/readings_controller.dart';
import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/duplicate_decision.dart';
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
  });

  test('edita, exclui e limpa todos os codigos ativos', () async {
    final repository = _FakeReadingsRepository(
      seeded: [
        _item(id: 'a', code: '111', source: 'camera'),
        _item(id: 'b', code: '222', source: 'manual'),
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
      newCode: '333',
    );
    await notifier.deleteCode('b');

    var items = await container.read(readingsControllerProvider.future);
    expect(items.map((item) => item.code), ['333']);

    await notifier.clearAll();
    items = await container.read(readingsControllerProvider.future);
    expect(items, isEmpty);
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
