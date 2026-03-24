import 'dart:async';

import 'package:barcode_app/features/sync/domain/sync_operation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return ConnectivitySyncRepository();
});

abstract class SyncRepository {
  Future<bool> checkOnlineStatus();
  Stream<bool> watchOnlineStatus();
  Future<List<SyncOperation>> listPendingOperations();
  Future<void> pushOperation(SyncOperation operation);
  Future<void> markCompleted(String id);
  Future<void> markFailed(String id, String message);
}

class ConnectivitySyncRepository implements SyncRepository {
  ConnectivitySyncRepository({
    Connectivity? connectivity,
    List<SyncOperation>? seededOperations,
  })  : _connectivity = connectivity ?? Connectivity(),
        _pendingOperations = List.of(seededOperations ?? const []);

  final Connectivity _connectivity;
  final List<SyncOperation> _pendingOperations;
  final Map<String, _FailureState> _failureStates = {};

  @override
  Future<bool> checkOnlineStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _hasConnection(results);
    } on MissingPluginException {
      return true;
    }
  }

  @override
  Future<List<SyncOperation>> listPendingOperations() async {
    return List.unmodifiable(_pendingOperations);
  }

  @override
  Future<void> markCompleted(String id) async {
    _pendingOperations.removeWhere((item) => item.id == id);
    _failureStates.remove(id);
  }

  @override
  Future<void> markFailed(String id, String message) async {
    final attempts = (_failureStates[id]?.attempts ?? 0) + 1;
    _failureStates[id] = _FailureState(
      attempts: attempts,
      message: message,
    );
  }

  @override
  Future<void> pushOperation(SyncOperation operation) async {
    // Placeholder para integração futura com Supabase.
  }

  @override
  Stream<bool> watchOnlineStatus() {
    return Stream<bool>.multi((controller) {
      StreamSubscription<List<ConnectivityResult>>? subscription;

      try {
        subscription = _connectivity.onConnectivityChanged.listen(
          (results) => controller.add(_hasConnection(results)),
          onError: (_) {},
        );
      } on MissingPluginException {
        controller.close();
        return;
      }

      controller.onCancel = () => subscription?.cancel();
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}

class _FailureState {
  const _FailureState({
    required this.attempts,
    required this.message,
  });

  final int attempts;
  final String message;
}
