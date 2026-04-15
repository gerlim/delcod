import 'package:barcode_app/features/import/data/reading_import_service.dart';
import 'package:barcode_app/features/readings/domain/reading_classification.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final readingsImportCommitPlannerProvider =
    Provider<ReadingsImportCommitPlanner>(
  (ref) => const ReadingsImportCommitPlanner(),
);

class ReadingsImportCommitPlan {
  const ReadingsImportCommitPlan({
    required this.codesToImport,
    required this.classifications,
    required this.metadataPayloads,
    required this.skippedDuplicates,
  });

  final List<String> codesToImport;
  final List<ReadingClassification> classifications;
  final List<Map<String, dynamic>?> metadataPayloads;
  final int skippedDuplicates;

  bool get hasItemsToImport => codesToImport.isNotEmpty;
}

class ReadingsImportCommitPlanner {
  const ReadingsImportCommitPlanner();

  ReadingsImportCommitPlan build({
    required List<ImportedReadingEntry> entries,
    required Set<String> existingCodes,
    required bool includeDuplicates,
    required ReadingClassification Function(String code) classify,
    required Map<String, dynamic>? Function(
      ImportedReadingEntry entry,
      String normalizedCode,
    ) buildMetadataPayload,
  }) {
    final seenInImport = <String>{};
    final codesToImport = <String>[];
    final classifications = <ReadingClassification>[];
    final metadataPayloads = <Map<String, dynamic>?>[];
    var skippedDuplicates = 0;

    for (final entry in entries) {
      final code = entry.code;
      final duplicate =
          existingCodes.contains(code) || seenInImport.contains(code);
      final metadataPayload = buildMetadataPayload(entry, code);

      if (duplicate) {
        if (includeDuplicates) {
          codesToImport.add(code);
          classifications.add(classify(code));
          metadataPayloads.add(metadataPayload);
        } else {
          skippedDuplicates += 1;
        }
        continue;
      }

      seenInImport.add(code);
      codesToImport.add(code);
      classifications.add(classify(code));
      metadataPayloads.add(metadataPayload);
    }

    return ReadingsImportCommitPlan(
      codesToImport: codesToImport,
      classifications: classifications,
      metadataPayloads: metadataPayloads,
      skippedDuplicates: skippedDuplicates,
    );
  }
}
