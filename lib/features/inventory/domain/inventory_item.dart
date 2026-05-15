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

  InventoryItem copyWith({
    String? companyName,
    String? bobbinCode,
    String? itemDescription,
    String? barcode,
    String? weight,
    String? warehouse,
    Map<String, dynamic>? rawPayload,
  }) {
    return InventoryItem(
      id: id,
      auditId: auditId,
      companyName: companyName ?? this.companyName,
      bobbinCode: bobbinCode ?? this.bobbinCode,
      itemDescription: itemDescription ?? this.itemDescription,
      barcode: barcode ?? this.barcode,
      weight: weight ?? this.weight,
      warehouse: warehouse ?? this.warehouse,
      rowNumber: rowNumber,
      rawPayload: rawPayload ?? this.rawPayload,
    );
  }
}
