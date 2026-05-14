import 'package:barcode_app/features/inventory/application/inventory_export_builder.dart';
import 'package:barcode_app/features/inventory/data/inventory_repository.dart';
import 'package:barcode_app/features/inventory/domain/inventory_audit_result.dart';
import 'package:barcode_app/features/inventory/domain/inventory_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('groups audit snapshot into correct, incorrect, not found, and pending', () {
    final snapshot = InventoryAuditSnapshot(
      auditId: 'audit-1',
      items: const [
        InventoryItem(
          id: 'item-1',
          auditId: 'audit-1',
          companyName: 'Bora',
          bobbinCode: 'BOB-1',
          itemDescription: 'Papel',
          barcode: '111',
          weight: '10',
          warehouse: '05',
          rowNumber: 1,
        ),
        InventoryItem(
          id: 'item-2',
          auditId: 'audit-1',
          companyName: 'ABN',
          bobbinCode: 'BOB-2',
          itemDescription: 'Papel',
          barcode: '222',
          weight: '20',
          warehouse: 'GLR',
          rowNumber: 2,
        ),
      ],
      results: [
        InventoryAuditResult.correct(
          id: 'result-1',
          auditId: 'audit-1',
          inventoryItemId: 'item-1',
          scannedBarcode: '111',
          scannedAt: DateTime.utc(2026, 5, 14),
        ),
        InventoryAuditResult.notFound(
          id: 'result-2',
          auditId: 'audit-1',
          scannedBarcode: '999',
          scannedAt: DateTime.utc(2026, 5, 14),
        ),
      ],
    );

    final export = const InventoryExportBuilder().build(snapshot);

    expect(export.correct, hasLength(1));
    expect(export.incorrect, isEmpty);
    expect(export.notFound, hasLength(1));
    expect(export.pending, hasLength(1));
  });
}
