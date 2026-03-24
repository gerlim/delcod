import 'dart:async';

import 'package:barcode_app/features/sync/data/sync_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final syncControllerProvider = NotifierProvider<SyncController, SyncState>(
  SyncController.new,
);

final syncPollingEnabledProvider = Provider<bool>((ref) => true);

enum SyncStatus {
  offline,
  syncing,
  synced,
  failed,
}

class SyncState {
  const SyncState({
    required this.status,
    required this.pendingCount,
    this.lastError,
  });

  const SyncState.initial()
      : status = SyncStatus.synced,
        pendingCount = 0,
        lastError = null;

  final SyncStatus status;
  final int pendingCount;
  final String? lastError;

  String get label {
    switch (status) {
      case SyncStatus.offline:
        return 'Offline';
      case SyncStatus.syncing:
        return 'Sincronizando';
      case SyncStatus.synced:
        return 'Sincronizado';
      case SyncStatus.failed:
        return 'Falha na sincronização';
    }
  }

  SyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    String? lastError,
    bool clearError = false,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

class SyncController extends Notifier<SyncState> {
  Timer? _pollTimer;
  StreamSubscription<bool>? _connectivitySubscription;

  @override
  SyncState build() {
    final repository = ref.read(syncRepositoryProvider);

    _connectivitySubscription =
        repository.watchOnlineStatus().listen((isOnline) {
      if (!isOnline) {
        state = state.copyWith(
          status: SyncStatus.offline,
          clearError: true,
        );
        return;
      }

      unawaited(syncNow());
    });

    if (ref.read(syncPollingEnabledProvider)) {
      _pollTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => unawaited(syncNow()),
      );
    }

    ref.onDispose(() {
      _pollTimer?.cancel();
      _connectivitySubscription?.cancel();
    });

    unawaited(_loadInitialStatus());
    return const SyncState.initial();
  }

  Future<void> syncNow() async {
    final repository = ref.read(syncRepositoryProvider);
    final isOnline = await repository.checkOnlineStatus();

    if (!isOnline) {
      state = state.copyWith(
        status: SyncStatus.offline,
        clearError: true,
      );
      return;
    }

    final pending = await repository.listPendingOperations();
    if (pending.isEmpty) {
      state = state.copyWith(
        status: SyncStatus.synced,
        pendingCount: 0,
        clearError: true,
      );
      return;
    }

    state = state.copyWith(
      status: SyncStatus.syncing,
      pendingCount: pending.length,
      clearError: true,
    );

    for (final operation in pending) {
      try {
        await repository.pushOperation(operation);
        await repository.markCompleted(operation.id);
      } catch (error) {
        await repository.markFailed(operation.id, error.toString());
        state = state.copyWith(
          status: SyncStatus.failed,
          pendingCount: pending.length,
          lastError: error.toString(),
        );
        return;
      }
    }

    final remaining = await repository.listPendingOperations();
    state = state.copyWith(
      status: remaining.isEmpty ? SyncStatus.synced : SyncStatus.syncing,
      pendingCount: remaining.length,
      clearError: true,
    );
  }

  Future<void> _loadInitialStatus() async {
    final repository = ref.read(syncRepositoryProvider);
    final isOnline = await repository.checkOnlineStatus();

    if (!isOnline) {
      state = state.copyWith(
        status: SyncStatus.offline,
        clearError: true,
      );
      return;
    }

    final pending = await repository.listPendingOperations();
    state = state.copyWith(
      status: pending.isEmpty ? SyncStatus.synced : SyncStatus.syncing,
      pendingCount: pending.length,
      clearError: true,
    );
  }
}
