class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.auditId,
    required this.companyName,
    required this.bobbinCode,
    required this.itemDescription,
    required this.barcode,
    required this.weight,
    required this.warehouse,
    required this.rowNumber,
    this.rawPayload = const <String, dynamic>{},
  });

  final String id;
  final String auditId;
  final String companyName;
  final String bobbinCode;
  final String itemDescription;
  final String barcode;
  final String weight;
  final String warehouse;
  final int rowNumber;
  final Map<String, dynamic> rawPayload;

  String get lookupBarcode => barcode.trim();
}
