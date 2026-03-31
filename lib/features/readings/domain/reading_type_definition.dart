class ReadingTypeDefinition {
  const ReadingTypeDefinition({
    required this.id,
    required this.matches,
    this.buildPayload,
  });

  final String id;
  final bool Function(String code) matches;
  final Map<String, dynamic>? Function(String code)? buildPayload;
}
