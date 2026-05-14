abstract final class InventoryAuditsRemoteContract {
  static const tableName = 'inventory_audits';

  static const id = 'id';
  static const title = 'title';
  static const status = 'status';
  static const importedAt = 'imported_at';
  static const itemCount = 'item_count';
  static const sourceFilename = 'source_filename';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
}

abstract final class InventoryItemsRemoteContract {
  static const tableName = 'inventory_items';

  static const id = 'id';
  static const auditId = 'audit_id';
  static const companyName = 'company_name';
  static const bobbinCode = 'bobbin_code';
  static const itemDescription = 'item_description';
  static const barcode = 'barcode';
  static const weight = 'weight';
  static const warehouse = 'warehouse';
  static const rowNumber = 'row_number';
  static const rawPayload = 'raw_payload';
  static const createdAt = 'created_at';
}

abstract final class InventoryAuditResultsRemoteContract {
  static const tableName = 'inventory_audit_results';

  static const id = 'id';
  static const auditId = 'audit_id';
  static const inventoryItemId = 'inventory_item_id';
  static const scannedBarcode = 'scanned_barcode';
  static const status = 'status';
  static const discrepancyFields = 'discrepancy_fields';
  static const note = 'note';
  static const deviceId = 'device_id';
  static const scannedAt = 'scanned_at';
  static const createdAt = 'created_at';
}
