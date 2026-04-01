class WarehouseAllocationResult {
  const WarehouseAllocationResult({
    required this.updatedCount,
    required this.overwrittenCount,
  });

  final int updatedCount;
  final int overwrittenCount;
}
