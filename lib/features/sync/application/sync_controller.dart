import 'dart:async';

import 'package:barcode_app/features/readings/data/readings_repository.dart';
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
        return 'Falha na sincronizacao';
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
    final repository = ref.read(readingsRepositoryProvider);

    _connectivitySubscription = repository.watchOnlineStatus().listen((online) {
      if (!online) {
        state = state.copyWith(
          status: SyncStatus.offline,
          clearError: true,
        );
        return;
      }

      unawaited(refresh());
    });

    if (ref.read(syncPollingEnabledProvider)) {
      _pollTimer = Timer.periodic(
        const Duration(seconds: 20),
        (_) => unawaited(refresh()),
      );
    }

    ref.onDispose(() {
      _pollTimer?.cancel();
      _connectivitySubscription?.cancel();
    });

    unawaited(refresh());
    return const SyncState.initial();
  }

  Future<void> refresh() async {
    final repository = ref.read(readingsRepositoryProvider);
    final online = await repository.checkOnlineStatus();

    if (!online) {
      state = state.copyWith(
        status: SyncStatus.offline,
        pendingCount: await repository.pendingCount(),
        clearError: true,
      );
      return;
    }

    final pendingBefore = await repository.pendingCount();
    state = state.copyWith(
      status: pendingBefore == 0 ? SyncStatus.synced : SyncStatus.syncing,
      pendingCount: pendingBefore,
      clearError: true,
    );

    try {
      await repository.syncNow();
      final pendingAfter = await repository.pendingCount();
      state = state.copyWith(
        status: pendingAfter == 0 ? SyncStatus.synced : SyncStatus.syncing,
        pendingCount: pendingAfter,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: SyncStatus.failed,
        pendingCount: await repository.pendingCount(),
        lastError: error.toString(),
      );
    }
  }
}
