import 'package:flutter/foundation.dart';

enum ReadingClassificationStatus {
  identified,
  ambiguous,
  unknown;

  String get value => name;

  static ReadingClassificationStatus fromValue(String? value) {
    return switch (value) {
      'identified' => ReadingClassificationStatus.identified,
      'ambiguous' => ReadingClassificationStatus.ambiguous,
      _ => ReadingClassificationStatus.unknown,
    };
  }
}

@immutable
class ReadingClassification {
  const ReadingClassification._({
    required this.codeType,
    required this.classificationStatus,
    required this.classificationCandidates,
    required this.detailsPayload,
    required this.schemaVersion,
  });

  factory ReadingClassification.identified(
    String codeType, {
    Map<String, dynamic>? detailsPayload,
    int schemaVersion = 1,
  }) {
    return ReadingClassification._(
      codeType: codeType,
      classificationStatus: ReadingClassificationStatus.identified,
      classificationCandidates: const <String>[],
      detailsPayload: detailsPayload == null
          ? null
          : Map<String, dynamic>.unmodifiable(detailsPayload),
      schemaVersion: schemaVersion,
    );
  }

  factory ReadingClassification.ambiguous(
    List<String> candidates, {
    int schemaVersion = 1,
  }) {
    return ReadingClassification._(
      codeType: 'unknown',
      classificationStatus: ReadingClassificationStatus.ambiguous,
      classificationCandidates: List<String>.unmodifiable(
        _normalizeCandidates(candidates),
      ),
      detailsPayload: null,
      schemaVersion: schemaVersion,
    );
  }

  factory ReadingClassification.unknown({
    int schemaVersion = 1,
  }) {
    return ReadingClassification._(
      codeType: 'unknown',
      classificationStatus: ReadingClassificationStatus.unknown,
      classificationCandidates: const <String>[],
      detailsPayload: null,
      schemaVersion: schemaVersion,
    );
  }

  factory ReadingClassification.stored({
    required String codeType,
    required ReadingClassificationStatus classificationStatus,
    required List<String> classificationCandidates,
    required Map<String, dynamic>? detailsPayload,
    required int schemaVersion,
  }) {
    return switch (classificationStatus) {
      ReadingClassificationStatus.identified => ReadingClassification.identified(
          codeType,
          detailsPayload: detailsPayload,
          schemaVersion: schemaVersion,
        ),
      ReadingClassificationStatus.ambiguous => ReadingClassification.ambiguous(
          classificationCandidates,
          schemaVersion: schemaVersion,
        ),
      ReadingClassificationStatus.unknown => ReadingClassification.unknown(
          schemaVersion: schemaVersion,
        ),
    };
  }

  factory ReadingClassification.fromJson(Map<String, dynamic> json) {
    final status = ReadingClassificationStatus.fromValue(
      json['classification_status'] as String?,
    );
    final rawCandidates = (json['classification_candidates'] as List<dynamic>?)
            ?.map((entry) => entry.toString())
            .toList(growable: false) ??
        const <String>[];

    final rawPayload = json['details_payload'];
    return ReadingClassification.stored(
      codeType: (json['code_type'] as String?) ?? 'unknown',
      classificationStatus: status,
      classificationCandidates: rawCandidates,
      detailsPayload: rawPayload is Map<String, dynamic>
          ? rawPayload
          : rawPayload is Map
              ? Map<String, dynamic>.from(rawPayload)
              : null,
      schemaVersion: (json['schema_version'] as int?) ?? 1,
    );
  }

  final String codeType;
  final ReadingClassificationStatus classificationStatus;
  final List<String> classificationCandidates;
  final Map<String, dynamic>? detailsPayload;
  final int schemaVersion;

  Map<String, dynamic> toJson() {
    return {
      'code_type': codeType,
      'classification_status': classificationStatus.value,
      'classification_candidates': classificationCandidates,
      'details_payload': detailsPayload,
      'schema_version': schemaVersion,
    };
  }

  static List<String> _normalizeCandidates(List<String> values) {
    final normalized = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || normalized.contains(trimmed)) {
        continue;
      }
      normalized.add(trimmed);
    }
    return normalized;
  }
}
