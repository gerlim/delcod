class ImportCommitResult {
  const ImportCommitResult({
    required this.importedCount,
    required this.skippedDuplicates,
  });

  final int importedCount;
  final int skippedDuplicates;
}
