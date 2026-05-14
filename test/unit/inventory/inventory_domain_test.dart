import 'package:barcode_app/features/inventory/domain/inventory_audit_result.dart';
import 'package:barcode_app/features/inventory/domain/inventory_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'inventory item normalizes barcode for lookup without mutating source fields',
    () {
      final item = InventoryItem(
        id: 'item-1',
        auditId: 'audit-1',
        companyName: 'Bora Embalagens',
        bobbinCode: ' BOB-001 ',
        itemDescription: 'Papel kraft',
        barcode: ' 789123 ',
        weight: '482,5',
        warehouse: '05',
        rowNumber: 2,
      );

      expect(item.lookupBarcode, '789123');
      expect(item.bobbinCode, ' BOB-001 ');
    },
  );

  test('incorrect audit result stores discrepancy fields and optional note', () {
    final result = InventoryAuditResult.incorrect(
      id: 'result-1',
      auditId: 'audit-1',
      inventoryItemId: 'item-1',
      scannedBarcode: '789123',
      discrepancyFields: const {InventoryDiscrepancyField.weight},
      note: 'Peso na etiqueta esta diferente',
      scannedAt: DateTime.utc(2026, 5, 14),
    );

    expect(result.status, InventoryAuditResultStatus.incorrect);
    expect(
      result.discrepancyFields,
      contains(InventoryDiscrepancyField.weight),
    );
    expect(result.note, 'Peso na etiqueta esta diferente');
  });
}
