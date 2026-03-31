import 'package:barcode_app/features/readings/domain/reading_classification.dart';
import 'package:barcode_app/features/readings/domain/reading_type_definition.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final readingTypeClassifierProvider = Provider<ReadingTypeClassifier>((ref) {
  return ReadingTypeClassifier(
    definitions: defaultReadingTypeDefinitions,
  );
});

class ReadingTypeClassifier {
  const ReadingTypeClassifier({
    required this.definitions,
  });

  final List<ReadingTypeDefinition> definitions;

  ReadingClassification classify(String code) {
    final normalized = code.trim();
    final matches = <ReadingTypeDefinition>[];

    for (final definition in definitions) {
      if (definition.matches(normalized)) {
        matches.add(definition);
      }
    }

    if (matches.isEmpty) {
      return ReadingClassification.unknown();
    }

    if (matches.length > 1) {
      return ReadingClassification.ambiguous(
        matches.map((entry) => entry.id).toList(growable: false),
      );
    }

    final selected = matches.single;
    return ReadingClassification.identified(
      selected.id,
      detailsPayload: selected.buildPayload?.call(normalized),
    );
  }
}

final List<ReadingTypeDefinition> defaultReadingTypeDefinitions =
    <ReadingTypeDefinition>[
  ReadingTypeDefinition(
    id: 'paper_bobbin',
    matches: (code) {
      final normalized = code.trim().toLowerCase();
      if (normalized.startsWith('mg')) {
        return true;
      }
      if (RegExp(r'^\d{8,}$').hasMatch(normalized)) {
        return true;
      }
      return RegExp(r'\(\d{2,4}\)').hasMatch(normalized);
    },
    buildPayload: (code) {
      final normalized = code.trim();
      if (normalized.toLowerCase().startsWith('mg')) {
        return {
          'family': 'mg',
        };
      }
      return null;
    },
  ),
  const ReadingTypeDefinition(
    id: 'paper_sheet',
    matches: _neverMatches,
  ),
];

bool _neverMatches(String _) => false;
