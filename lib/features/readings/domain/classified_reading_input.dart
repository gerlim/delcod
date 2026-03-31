import 'package:barcode_app/features/readings/domain/reading_classification.dart';
import 'package:flutter/foundation.dart';

@immutable
class ClassifiedReadingInput {
  const ClassifiedReadingInput({
    required this.code,
    required this.source,
    required this.classification,
  });

  final String code;
  final String source;
  final ReadingClassification classification;
}
