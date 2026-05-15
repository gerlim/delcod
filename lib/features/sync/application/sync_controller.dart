import 'dart:async';

import 'package:barcode_app/features/inventory/data/inventory_repository.dart';
import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/sync/domain/sync_log_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:barcode_app/features/sync/domain/sync_log_entry.dart'
    show SyncLogEntry, SyncStatus;

final syncControllerProvider = NotifierProvider<SyncController, SyncState>(
  SyncController.new,
);

final syncPollingEnabledProvider = Provider<bool>((ref) => true);

class SyncState {
  const SyncState({
    required this.status,
    required this.pendingCount,
    this.lastError,
    this.lastAttemptAt,
    this.lastSyncedAt,
    this.recentEvents = const <SyncLogEntry>[],
  });

  const SyncState.initial()
      : status = SyncStatus.synced,
        pendingCount = 0,
        lastError = null,
        lastAttemptAt = null,
        lastSyncedAt = null,
        recentEvents = const <SyncLogEntry>[];

  final SyncStatus status;
  final int pendingCount;
  final String? lastError;
  final DateTime? lastAttemptAt;
  final DateTime? lastSyncedAt;
  final List<SyncLogEntry> recentEvents;

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
    DateTime? lastAttemptAt,
    DateTime? lastSyncedAt,
    List<SyncLogEntry>? recentEvents,
    bool clearError = false,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      recentEvents: recentEvents ?? this.recentEvents,
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
    final attemptAt = DateTime.now();
    final online = await repository.checkOnlineStatus();

    if (!online) {
      state = _appendEvent(
        state.copyWith(
          status: SyncStatus.offline,
          pendingCount: await _pendingCount(repository),
          lastAttemptAt: attemptAt,
          clearError: true,
        ),
        status: SyncStatus.offline,
        message: 'Sem conexao. Aguardando internet para sincronizar.',
      );
      return;
    }

    final pendingBefore = await _pendingCount(repository);
    state = state.copyWith(
      status: pendingBefore == 0 ? SyncStatus.synced : SyncStatus.syncing,
      pendingCount: pendingBefore,
      lastAttemptAt: attemptAt,
      clearError: true,
    );

    try {
      await repository.syncNow();
      await ref.read(inventoryRepositoryProvider).syncPendingResults();
      final pendingAfter = await _pendingCount(repository);
      final nextStatus =
          pendingAfter == 0 ? SyncStatus.synced : SyncStatus.syncing;
      state = _appendEvent(
        state.copyWith(
          status: nextStatus,
          pendingCount: pendingAfter,
          lastSyncedAt: pendingAfter == 0 ? DateTime.now() : state.lastSyncedAt,
          clearError: true,
        ),
        status: nextStatus,
        message: pendingAfter == 0
            ? 'Sincronizacao concluida com sucesso.'
            : '$pendingAfter operacoes ainda aguardando envio.',
      );
    } catch (error) {
      final message = error.toString();
      state = _appendEvent(
        state.copyWith(
          status: SyncStatus.failed,
          pendingCount: await _pendingCount(repository),
          lastError: message,
        ),
        status: SyncStatus.failed,
        message: message,
      );
    }
  }

  SyncState _appendEvent(
    SyncState nextState, {
    required SyncStatus status,
    required String message,
  }) {
    final trimmedMessage = message.trim();
    final recentEvents = <SyncLogEntry>[
      SyncLogEntry(
        occurredAt: DateTime.now(),
        status: status,
        message: trimmedMessage,
      ),
      ...nextState.recentEvents,
    ];

    return nextState.copyWith(
      recentEvents: recentEvents.take(12).toList(growable: false),
    );
  }

  Future<int> _pendingCount(ReadingsRepository repository) async {
    return await repository.pendingCount() +
        await ref.read(inventoryRepositoryProvider).pendingResultCount();
  }
}
