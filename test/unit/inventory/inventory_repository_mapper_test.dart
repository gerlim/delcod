import 'package:barcode_app/features/inventory/data/inventory_audit_mapper.dart';
import 'package:barcode_app/features/inventory/data/inventory_audit_result_mapper.dart';
import 'package:barcode_app/features/inventory/data/inventory_item_mapper.dart';
import 'package:barcode_app/features/inventory/domain/inventory_audit.dart';
import 'package:barcode_app/features/inventory/domain/inventory_audit_result.dart';
import 'package:barcode_app/features/inventory/domain/inventory_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('InventoryAuditMapper roundtrips audit rows', () {
    final audit = InventoryAudit(
      id: 'audit-1',
      title: 'Auditoria maio',
      status: InventoryAuditStatus.active,
      importedAt: DateTime.utc(2026, 5, 14, 10),
      itemCount: 2,
      sourceFilename: 'inventario.xlsx',
      createdAt: DateTime.utc(2026, 5, 14, 10),
      updatedAt: DateTime.utc(2026, 5, 14, 11),
    );

    final row = InventoryAuditMapper.toJson(audit);
    final hydrated = InventoryAuditMapper.fromJson(row);

    expect(hydrated.id, audit.id);
    expect(hydrated.isActive, isTrue);
    expect(hydrated.sourceFilename, 'inventario.xlsx');
  });

  test('InventoryItemMapper roundtrips imported item rows', () {
    final item = InventoryItem(
      id: 'item-1',
      auditId: 'audit-1',
      companyName: 'Bora Embalagens',
      bobbinCode: 'BOB-001',
      itemDescription: 'Papel kraft',
      barcode: '789001',
      weight: '482,5',
      warehouse: '05',
      rowNumber: 2,
      rawPayload: const {'Empresa': 'Bora Embalagens'},
    );

    final row = InventoryItemMapper.toJson(item);
    final hydrated = InventoryItemMapper.fromJson(row);

    expect(hydrated.companyName, item.companyName);
    expect(hydrated.barcode, item.barcode);
    expect(hydrated.rawPayload['Empresa'], 'Bora Embalagens');
  });

  test('InventoryAuditResultMapper roundtrips incorrect result rows', () {
    final result = InventoryAuditResult.incorrect(
      id: 'result-1',
      auditId: 'audit-1',
      inventoryItemId: 'item-1',
      scannedBarcode: '789001',
      discrepancyFields: const {
        InventoryDiscrepancyField.weight,
        InventoryDiscrepancyField.warehouse,
      },
      note: 'Armazem fisico diferente',
      scannedAt: DateTime.utc(2026, 5, 14, 12, 30),
    );

    final row = InventoryAuditResultMapper.toJson(result);
    final hydrated = InventoryAuditResultMapper.fromJson(row);

    expect(hydrated.status, InventoryAuditResultStatus.incorrect);
    expect(hydrated.discrepancyFields, contains(InventoryDiscrepancyField.weight));
    expect(hydrated.discrepancyFields, contains(InventoryDiscrepancyField.warehouse));
    expect(hydrated.note, 'Armazem fisico diferente');
  });
}
