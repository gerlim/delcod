import 'dart:async';

import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/reading_classification.dart';
import 'package:barcode_app/features/sync/application/sync_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('marca ultimo sync e adiciona evento quando sincroniza com sucesso',
      () async {
    final repository = _FakeSyncReadingsRepository(
      online: true,
      pendingCounts: <int>[2, 0],
    );

    final container = ProviderContainer(
      overrides: [
        readingsRepositoryProvider.overrideWithValue(repository),
        syncPollingEnabledProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    container.read(syncControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final state = container.read(syncControllerProvider);

    expect(state.status, SyncStatus.synced);
    expect(state.pendingCount, 0);
    expect(state.lastAttemptAt, isNotNull);
    expect(state.lastSyncedAt, isNotNull);
    expect(state.recentEvents, isNotEmpty);
    expect(state.recentEvents.first.status, SyncStatus.synced);
  });

  test('guarda erro e evento tecnico quando a sincronizacao falha', () async {
    final repository = _FakeSyncReadingsRepository(
      online: true,
      pendingCounts: <int>[1, 1],
      syncError: Exception('remote timeout'),
    );

    final container = ProviderContainer(
      overrides: [
        readingsRepositoryProvider.overrideWithValue(repository),
        syncPollingEnabledProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    container.read(syncControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final state = container.read(syncControllerProvider);

    expect(state.status, SyncStatus.failed);
    expect(state.pendingCount, 1);
    expect(state.lastAttemptAt, isNotNull);
    expect(state.lastSyncedAt, isNull);
    expect(state.lastError, contains('remote timeout'));
    expect(state.recentEvents, isNotEmpty);
    expect(state.recentEvents.first.status, SyncStatus.failed);
  });
}

class _FakeSyncReadingsRepository implements ReadingsRepository {
  _FakeSyncReadingsRepository({
    required this.online,
    required List<int> pendingCounts,
    this.syncError,
  }) : _pendingCounts = List<int>.from(pendingCounts);

  final bool online;
  final Object? syncError;
  final List<int> _pendingCounts;

  int _readPendingCount() {
    if (_pendingCounts.isEmpty) {
      return 0;
    }
    if (_pendingCounts.length == 1) {
      return _pendingCounts.first;
    }
    return _pendingCounts.removeAt(0);
  }

  @override
  Future<int> pendingCount() async => _readPendingCount();

  @override
  Future<bool> checkOnlineStatus() async => online;

  @override
  Stream<bool> watchOnlineStatus() => Stream<bool>.value(online);

  @override
  Future<void> syncNow() async {
    if (syncError != null) {
      throw syncError!;
    }
  }

  @override
  Future<ReadingItem> addCode({
    required String code,
    required String source,
    ReadingClassification? classification,
    Map<String, dynamic>? metadataPayload,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<ReadingItem>> addCodesBatch({
    required List<String> codes,
    required String source,
    List<ReadingClassification>? classifications,
    List<Map<String, dynamic>?>? metadataPayloads,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> clearAll() {
    throw UnimplementedError();
  }

  @override
  void dispose() {}

  @override
  Future<bool> existsCode(String code, {String? excludingId}) {
    throw UnimplementedError();
  }

  @override
  Future<List<ReadingItem>> fetchActive() async => const <ReadingItem>[];

  @override
  Future<void> softDelete(String id) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateCode({
    required String id,
    required String newCode,
    ReadingClassification? classification,
    Map<String, dynamic>? metadataPayload,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<ReadingItem>> watchActive() =>
      const Stream<List<ReadingItem>>.empty();
}
