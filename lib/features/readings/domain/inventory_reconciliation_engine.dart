import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/bobbin_inventory_record.dart';
import 'package:barcode_app/features/readings/domain/inventory_reconciliation.dart';

class InventoryReconciliationEngine {
  const InventoryReconciliationEngine();

  InventoryReconciliationSnapshot reconcile(List<ReadingItem> items) {
    final grouped = <String, List<ReadingItem>>{};

    for (final item in items) {
      if (item.deletedAt != null) {
        continue;
      }

      final inventoryRecord = BobbinInventoryRecord.fromItem(item);
      final lot = inventoryRecord.lot.trim();
      if (lot.isEmpty) {
        continue;
      }
      grouped.putIfAbsent(lot, () => <ReadingItem>[]).add(item);
    }

    final byLot = <String, InventoryReconciliationEntry>{};
    final sortedLots = grouped.keys.toList(growable: false)..sort();
    for (final lot in sortedLots) {
      final lotItems = grouped[lot]!;
      final expectedItems = lotItems
          .where(
            (item) => InventoryReadingRole.fromSource(item.source) ==
                InventoryReadingRole.expected,
          )
          .toList(growable: false);
      final countedItems = lotItems
          .where(
            (item) => InventoryReadingRole.fromSource(item.source) ==
                InventoryReadingRole.counted,
          )
          .toList(growable: false);

      final presenceStatus = _resolvePresenceStatus(
        expectedItems: expectedItems,
        countedItems: countedItems,
      );
      final expectedWarehouses = _extractWarehouses(expectedItems);
      final countedWarehouses = _extractWarehouses(countedItems);

      byLot[lot] = InventoryReconciliationEntry(
        lot: lot,
        expectedItems: expectedItems,
        countedItems: countedItems,
        expectedWarehouses: expectedWarehouses,
        countedWarehouses: countedWarehouses,
        presenceStatus: presenceStatus,
        warehouseStatus: _resolveWarehouseStatus(
          expectedItems: expectedItems,
          countedItems: countedItems,
          expectedWarehouses: expectedWarehouses,
          countedWarehouses: countedWarehouses,
        ),
      );
    }

    return InventoryReconciliationSnapshot(byLot: byLot);
  }

  InventoryPresenceStatus _resolvePresenceStatus({
    required List<ReadingItem> expectedItems,
    required List<ReadingItem> countedItems,
  }) {
    if (expectedItems.isNotEmpty && countedItems.isNotEmpty) {
      return InventoryPresenceStatus.matched;
    }
    if (expectedItems.isNotEmpty) {
      return InventoryPresenceStatus.expectedOnly;
    }
    return InventoryPresenceStatus.countedOnly;
  }

  Set<String> _extractWarehouses(List<ReadingItem> items) {
    final warehouses = <String>{};
    for (final item in items) {
      final warehouseCode = BobbinInventoryRecord.fromItem(item).warehouseCode;
      if (warehouseCode != null && warehouseCode.isNotEmpty) {
        warehouses.add(warehouseCode);
      }
    }
    return warehouses;
  }

  InventoryWarehouseStatus _resolveWarehouseStatus({
    required List<ReadingItem> expectedItems,
    required List<ReadingItem> countedItems,
    required Set<String> expectedWarehouses,
    required Set<String> countedWarehouses,
  }) {
    if (expectedItems.isEmpty || countedItems.isEmpty) {
      return InventoryWarehouseStatus.notApplicable;
    }
    if (expectedWarehouses.isEmpty || countedWarehouses.isEmpty) {
      return InventoryWarehouseStatus.unknown;
    }
    if (_sameSet(expectedWarehouses, countedWarehouses)) {
      return InventoryWarehouseStatus.aligned;
    }
    return InventoryWarehouseStatus.mismatch;
  }

  bool _sameSet(Set<String> left, Set<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (final value in left) {
      if (!right.contains(value)) {
        return false;
      }
    }
    return true;
  }
}
