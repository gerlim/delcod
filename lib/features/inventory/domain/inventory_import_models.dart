class InventoryItemDraft {
  const InventoryItemDraft({
    required this.companyName,
    required this.bobbinCode,
    required this.itemDescription,
    required this.barcode,
    required this.weight,
    required this.warehouse,
    required this.rowNumber,
    required this.rawPayload,
  });

  final String companyName;
  final String bobbinCode;
  final String itemDescription;
  final String barcode;
  final String weight;
  final String warehouse;
  final int rowNumber;
  final Map<String, String> rawPayload;
}

class InventoryImportValidation {
  const InventoryImportValidation({
    required this.filename,
    required this.items,
    required this.errors,
  });

  final String filename;
  final List<InventoryItemDraft> items;
  final List<InventoryImportError> errors;

  bool get isValid => errors.isEmpty;
}

class InventoryImportError {
  const InventoryImportError({
    required this.message,
    this.rowNumber,
  });

  final String message;
  final int? rowNumber;
}
