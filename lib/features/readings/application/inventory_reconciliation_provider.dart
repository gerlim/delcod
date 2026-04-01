import 'package:barcode_app/features/readings/application/readings_controller.dart';
import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/inventory_reconciliation.dart';
import 'package:barcode_app/features/readings/domain/inventory_reconciliation_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final inventoryReconciliationEngineProvider =
    Provider<InventoryReconciliationEngine>((ref) {
  return const InventoryReconciliationEngine();
});

final inventoryReconciliationSnapshotProvider =
    Provider<InventoryReconciliationSnapshot>((ref) {
  final items =
      ref.watch(readingsControllerProvider).valueOrNull ?? const <ReadingItem>[];
  final engine = ref.watch(inventoryReconciliationEngineProvider);
  return engine.reconcile(items);
});
