import 'package:barcode_app/features/sync/application/sync_controller.dart';
import 'package:barcode_app/features/sync/data/sync_repository.dart';
import 'package:barcode_app/features/sync/domain/sync_operation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sincroniza itens pendentes quando estiver online', () async {
    final repository = _FakeSyncRepository(
      isOnline: true,
      pending: const [
        SyncOperation(
          id: 'sync-1',
          entity: 'readings',
          operation: 'insert',
          payload: '{"code":"7891234567890"}',
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        syncPollingEnabledProvider.overrideWithValue(false),
        syncRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(syncControllerProvider.notifier).syncNow();

    expect(repository.completedIds, ['sync-1']);
    expect(container.read(syncControllerProvider).status, SyncStatus.synced);
  });
}

class _FakeSyncRepository implements SyncRepository {
  _FakeSyncRepository({
    required this.isOnline,
    required List<SyncOperation> pending,
  }) : _pending = List.of(pending);

  final bool isOnline;
  final List<SyncOperation> _pending;
  final List<String> completedIds = [];

  @override
  Future<bool> checkOnlineStatus() async => isOnline;

  @override
  Future<List<SyncOperation>> listPendingOperations() async =>
      List.unmodifiable(_pending);

  @override
  Future<void> markCompleted(String id) async {
    completedIds.add(id);
    _pending.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> markFailed(String id, String message) async {}

  @override
  Future<void> pushOperation(SyncOperation operation) async {}

  @override
  Stream<bool> watchOnlineStatus() => const Stream<bool>.empty();
}
