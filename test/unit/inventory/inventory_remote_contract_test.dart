import 'package:barcode_app/features/inventory/data/inventory_remote_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inventory remote contract exposes canonical table names', () {
    expect(InventoryAuditsRemoteContract.tableName, 'inventory_audits');
    expect(InventoryItemsRemoteContract.tableName, 'inventory_items');
    expect(
      InventoryAuditResultsRemoteContract.tableName,
      'inventory_audit_results',
    );
  });

  test('inventory remote contract exposes lookup columns', () {
    expect(InventoryItemsRemoteContract.auditId, 'audit_id');
    expect(InventoryItemsRemoteContract.barcode, 'barcode');
    expect(InventoryAuditResultsRemoteContract.scannedBarcode, 'scanned_barcode');
    expect(InventoryAuditResultsRemoteContract.status, 'status');
  });
}
