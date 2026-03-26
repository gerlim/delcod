class ExportReadingsPayload {
  const ExportReadingsPayload({
    required this.title,
    required this.codes,
  });

  final String title;
  final List<String> codes;
}
