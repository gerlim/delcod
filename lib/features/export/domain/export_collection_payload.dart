class ExportCollectionPayload {
  const ExportCollectionPayload({
    required this.companyName,
    required this.collectionTitle,
    required this.rows,
  });

  final String companyName;
  final String collectionTitle;
  final List<ExportReadingRow> rows;
}

class ExportReadingRow {
  const ExportReadingRow({
    required this.code,
    required this.type,
    required this.source,
    required this.operatorName,
    required this.recordedAt,
  });

  final String code;
  final String type;
  final String source;
  final String operatorName;
  final DateTime recordedAt;
}
