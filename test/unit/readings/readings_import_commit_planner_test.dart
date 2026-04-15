import 'package:barcode_app/features/import/data/reading_import_service.dart';
import 'package:barcode_app/features/readings/application/readings_import_commit_planner.dart';
import 'package:barcode_app/features/readings/domain/reading_classification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReadingsImportCommitPlanner', () {
    const planner = ReadingsImportCommitPlanner();

    test('skips duplicate entries when includeDuplicates is false', () {
      final entries = <ImportedReadingEntry>[
        const ImportedReadingEntry(code: 'A'),
        const ImportedReadingEntry(code: 'A'),
        const ImportedReadingEntry(code: 'B'),
      ];

      final plan = planner.build(
        entries: entries,
        existingCodes: <String>{'B'},
        includeDuplicates: false,
        classify: (_) => ReadingClassification.unknown(),
        buildMetadataPayload: (_, __) => null,
      );

      expect(plan.codesToImport, <String>['A']);
      expect(plan.skippedDuplicates, 2);
      expect(plan.classifications.length, 1);
      expect(plan.metadataPayloads.length, 1);
    });

    test('keeps duplicate entries when includeDuplicates is true', () {
      final entries = <ImportedReadingEntry>[
        const ImportedReadingEntry(code: 'A'),
        const ImportedReadingEntry(code: 'A'),
        const ImportedReadingEntry(code: 'B'),
      ];

      final plan = planner.build(
        entries: entries,
        existingCodes: <String>{'B'},
        includeDuplicates: true,
        classify: (_) => ReadingClassification.unknown(),
        buildMetadataPayload: (entry, code) => <String, dynamic>{
          'lot': code,
          'raw': entry.code,
        },
      );

      expect(plan.codesToImport, <String>['A', 'A', 'B']);
      expect(plan.skippedDuplicates, 0);
      expect(plan.classifications.length, 3);
      expect(plan.metadataPayloads.length, 3);
      expect(
        plan.metadataPayloads.first,
        <String, dynamic>{'lot': 'A', 'raw': 'A'},
      );
    });
  });
}
