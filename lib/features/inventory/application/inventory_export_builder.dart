import 'package:barcode_app/features/inventory/data/inventory_repository.dart';
import 'package:barcode_app/features/inventory/domain/inventory_audit_result.dart';
import 'package:barcode_app/features/inventory/domain/inventory_item.dart';

class InventoryExportBuilder {
  const InventoryExportBuilder();

  InventoryAuditExport build(InventoryAuditSnapshot snapshot) {
    final itemById = <String, InventoryItem>{
      for (final item in snapshot.items) item.id: item,
    };
    final resultByItemId = <String, InventoryAuditResult>{};
    final notFound = <InventoryAuditExportRow>[];
    final correct = <InventoryAuditExportRow>[];
    final incorrect = <InventoryAuditExportRow>[];

    for (final result in snapshot.results) {
      final itemId = result.inventoryItemId;
      final item = itemId == null ? null : itemById[itemId];
      final row = InventoryAuditExportRow(item: item, result: result);
      switch (result.status) {
        case InventoryAuditResultStatus.correct:
          correct.add(row);
          if (itemId != null) {
            resultByItemId[itemId] = result;
          }
          break;
        case InventoryAuditResultStatus.incorrect:
          incorrect.add(row);
          if (itemId != null) {
            resultByItemId[itemId] = result;
          }
          break;
        case InventoryAuditResultStatus.notFound:
          notFound.add(row);
          break;
      }
    }

    final pending = snapshot.items
        .where((item) => !resultByItemId.containsKey(item.id))
        .map((item) => InventoryAuditExportRow(item: item, result: null))
        .toList(growable: false);

    return InventoryAuditExport(
      correct: correct,
      incorrect: incorrect,
      notFound: notFound,
      pending: pending,
    );
  }
}

class InventoryAuditExport {
  const InventoryAuditExport({
    required this.correct,
    required this.incorrect,
    required this.notFound,
    required this.pending,
  });

  final List<InventoryAuditExportRow> correct;
  final List<InventoryAuditExportRow> incorrect;
  final List<InventoryAuditExportRow> notFound;
  final List<InventoryAuditExportRow> pending;
}

class InventoryAuditExportRow {
  const InventoryAuditExportRow({
    required this.item,
    required this.result,
  });

  final InventoryItem? item;
  final InventoryAuditResult? result;
}
