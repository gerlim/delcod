enum InventoryAuditStatus {
  active,
  archived,
}

class InventoryAudit {
  const InventoryAudit({
    required this.id,
    required this.title,
    required this.status,
    required this.importedAt,
    required this.itemCount,
    required this.sourceFilename,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final InventoryAuditStatus status;
  final DateTime importedAt;
  final int itemCount;
  final String sourceFilename;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == InventoryAuditStatus.active;
}
