import 'dart:collection';

import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:flutter/foundation.dart';

enum InventoryPresenceStatus {
  expectedOnly,
  countedOnly,
  matched;
}

enum InventoryWarehouseStatus {
  aligned,
  mismatch,
  unknown,
  notApplicable;
}

enum InventoryReadingRole {
  expected,
  counted;

  static InventoryReadingRole fromSource(String source) {
    return source == 'import'
        ? InventoryReadingRole.expected
        : InventoryReadingRole.counted;
  }
}

@immutable
class InventoryReconciliationEntry {
  InventoryReconciliationEntry({
    required this.lot,
    required List<ReadingItem> expectedItems,
    required List<ReadingItem> countedItems,
    required Set<String> expectedWarehouses,
    required Set<String> countedWarehouses,
    required this.presenceStatus,
    required this.warehouseStatus,
  })  : expectedItems = UnmodifiableListView(expectedItems),
        countedItems = UnmodifiableListView(countedItems),
        expectedWarehouses = UnmodifiableSetView(expectedWarehouses),
        countedWarehouses = UnmodifiableSetView(countedWarehouses);

  final String lot;
  final List<ReadingItem> expectedItems;
  final List<ReadingItem> countedItems;
  final Set<String> expectedWarehouses;
  final Set<String> countedWarehouses;
  final InventoryPresenceStatus presenceStatus;
  final InventoryWarehouseStatus warehouseStatus;

  bool get isMissing => presenceStatus == InventoryPresenceStatus.expectedOnly;
  bool get isUnexpected =>
      presenceStatus == InventoryPresenceStatus.countedOnly;
  bool get isMatched => presenceStatus == InventoryPresenceStatus.matched;
  bool get hasWarehouseMismatch =>
      warehouseStatus == InventoryWarehouseStatus.mismatch;
}

@immutable
class InventoryReconciliationSnapshot {
  InventoryReconciliationSnapshot({
    required Map<String, InventoryReconciliationEntry> byLot,
  }) : byLot = UnmodifiableMapView(byLot);

  final Map<String, InventoryReconciliationEntry> byLot;

  Iterable<InventoryReconciliationEntry> get entries => byLot.values;

  int get matchedLotsCount => entries
      .where((entry) => entry.presenceStatus == InventoryPresenceStatus.matched)
      .length;

  int get missingLotsCount => entries
      .where(
        (entry) => entry.presenceStatus == InventoryPresenceStatus.expectedOnly,
      )
      .length;

  int get unexpectedLotsCount => entries
      .where(
        (entry) => entry.presenceStatus == InventoryPresenceStatus.countedOnly,
      )
      .length;

  int get warehouseMismatchLotsCount => entries
      .where(
        (entry) =>
            entry.warehouseStatus == InventoryWarehouseStatus.mismatch,
      )
      .length;

  int get unknownWarehouseLotsCount => entries
      .where(
        (entry) => entry.warehouseStatus == InventoryWarehouseStatus.unknown,
      )
      .length;
}
