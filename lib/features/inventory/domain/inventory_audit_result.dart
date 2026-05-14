enum InventoryAuditResultStatus {
  correct,
  incorrect,
  notFound,
}

enum InventoryDiscrepancyField {
  company,
  bobbinCode,
  description,
  barcode,
  weight,
  warehouse,
}

class InventoryAuditResult {
  const InventoryAuditResult({
    required this.id,
    required this.auditId,
    required this.inventoryItemId,
    required this.scannedBarcode,
    required this.status,
    required this.discrepancyFields,
    required this.note,
    required this.scannedAt,
  });

  factory InventoryAuditResult.correct({
    required String id,
    required String auditId,
    required String inventoryItemId,
    required String scannedBarcode,
    required DateTime scannedAt,
  }) {
    return InventoryAuditResult(
      id: id,
      auditId: auditId,
      inventoryItemId: inventoryItemId,
      scannedBarcode: scannedBarcode.trim(),
      status: InventoryAuditResultStatus.correct,
      discrepancyFields: const <InventoryDiscrepancyField>{},
      note: null,
      scannedAt: scannedAt,
    );
  }

  factory InventoryAuditResult.incorrect({
    required String id,
    required String auditId,
    required String inventoryItemId,
    required String scannedBarcode,
    required Set<InventoryDiscrepancyField> discrepancyFields,
    String? note,
    required DateTime scannedAt,
  }) {
    return InventoryAuditResult(
      id: id,
      auditId: auditId,
      inventoryItemId: inventoryItemId,
      scannedBarcode: scannedBarcode.trim(),
      status: InventoryAuditResultStatus.incorrect,
      discrepancyFields: Set.unmodifiable(discrepancyFields),
      note: _blankToNull(note),
      scannedAt: scannedAt,
    );
  }

  factory InventoryAuditResult.notFound({
    required String id,
    required String auditId,
    required String scannedBarcode,
    required DateTime scannedAt,
  }) {
    return InventoryAuditResult(
      id: id,
      auditId: auditId,
      inventoryItemId: null,
      scannedBarcode: scannedBarcode.trim(),
      status: InventoryAuditResultStatus.notFound,
      discrepancyFields: const <InventoryDiscrepancyField>{},
      note: null,
      scannedAt: scannedAt,
    );
  }

  final String id;
  final String auditId;
  final String? inventoryItemId;
  final String scannedBarcode;
  final InventoryAuditResultStatus status;
  final Set<InventoryDiscrepancyField> discrepancyFields;
  final String? note;
  final DateTime scannedAt;

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
