import 'package:barcode_app/features/readings/domain/reading_classification.dart';
import 'package:barcode_app/features/readings/domain/reading_type_classifier.dart';
import 'package:barcode_app/features/readings/domain/reading_type_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('identifica um unico tipo quando apenas uma definicao combina', () {
    final classifier = ReadingTypeClassifier(
      definitions: [
        ReadingTypeDefinition(
          id: 'paper_bobbin',
          matches: (code) => code.startsWith('BOB'),
          buildPayload: (code) => {
            'kind': 'bobbin',
            'raw': code,
          },
        ),
        ReadingTypeDefinition(
          id: 'paper_sheet',
          matches: (_) => false,
        ),
      ],
    );

    final result = classifier.classify('BOB-123');

    expect(result.codeType, 'paper_bobbin');
    expect(result.classificationStatus, ReadingClassificationStatus.identified);
    expect(result.classificationCandidates, isEmpty);
    expect(result.detailsPayload, {
      'kind': 'bobbin',
      'raw': 'BOB-123',
    });
  });

  test('retorna ambiguo quando mais de uma definicao combina', () {
    final classifier = ReadingTypeClassifier(
      definitions: [
        ReadingTypeDefinition(
          id: 'paper_bobbin',
          matches: (code) => code.startsWith('MIX'),
        ),
        ReadingTypeDefinition(
          id: 'paper_sheet',
          matches: (code) => code.startsWith('MIX'),
        ),
      ],
    );

    final result = classifier.classify('MIX-123');

    expect(result.codeType, 'unknown');
    expect(result.classificationStatus, ReadingClassificationStatus.ambiguous);
    expect(result.classificationCandidates, [
      'paper_bobbin',
      'paper_sheet',
    ]);
    expect(result.detailsPayload, isNull);
  });

  test('retorna unknown quando nenhuma definicao combina', () {
    final classifier = ReadingTypeClassifier(
      definitions: [
        ReadingTypeDefinition(
          id: 'paper_bobbin',
          matches: (code) => code.startsWith('BOB'),
        ),
      ],
    );

    final result = classifier.classify('XYZ-999');

    expect(result.codeType, 'unknown');
    expect(result.classificationStatus, ReadingClassificationStatus.unknown);
    expect(result.classificationCandidates, isEmpty);
    expect(result.detailsPayload, isNull);
  });
}
