class ReadingInput {
  const ReadingInput({
    required this.collectionId,
    required this.code,
    required this.source,
    this.codeType,
    this.operatorName,
    this.recordedAt,
  });

  final String collectionId;
  final String code;
  final String source;
  final String? codeType;
  final String? operatorName;
  final DateTime? recordedAt;
}
