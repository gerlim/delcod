class ExportReadingsPayload {
  const ExportReadingsPayload({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<ExportReadingRow> rows;
}

class ExportReadingRow {
  const ExportReadingRow({
    required this.lot,
    required this.warehouseCode,
    required this.companyName,
    required this.isPendingWarehouse,
  });

  final String lot;
  final String? warehouseCode;
  final String? companyName;
  final bool isPendingWarehouse;
}
