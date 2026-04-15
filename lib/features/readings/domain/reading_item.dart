import 'package:barcode_app/features/readings/domain/reading_classification.dart';
import 'package:flutter/foundation.dart';

@immutable
class ReadingItem {
  ReadingItem({
    required this.id,
    required this.code,
    required this.source,
    required this.updatedAt,
    required this.deletedAt,
    required this.deviceId,
    String codeType = 'unknown',
    ReadingClassificationStatus classificationStatus =
        ReadingClassificationStatus.unknown,
    List<String> classificationCandidates = const <String>[],
    Map<String, dynamic>? detailsPayload,
    Map<String, dynamic>? metadataPayload,
    int schemaVersion = 1,
    ReadingClassification? classification,
  })  : codeType = classification?.codeType ?? codeType,
        classificationStatus =
            classification?.classificationStatus ?? classificationStatus,
        classificationCandidates = classification?.classificationCandidates ??
            classificationCandidates,
        detailsPayload = classification?.detailsPayload ?? detailsPayload,
        metadataPayload = metadataPayload == null
            ? null
            : Map<String, dynamic>.unmodifiable(metadataPayload),
        schemaVersion = classification?.schemaVersion ?? schemaVersion;

  final String id;
  final String code;
  final String source;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String deviceId;
  final String codeType;
  final ReadingClassificationStatus classificationStatus;
  final List<String> classificationCandidates;
  final Map<String, dynamic>? detailsPayload;
  final Map<String, dynamic>? metadataPayload;
  final int schemaVersion;

  ReadingItem copyWith({
    String? id,
    String? code,
    String? source,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deviceId,
    String? codeType,
    ReadingClassificationStatus? classificationStatus,
    List<String>? classificationCandidates,
    Map<String, dynamic>? detailsPayload,
    Map<String, dynamic>? metadataPayload,
    int? schemaVersion,
    ReadingClassification? classification,
  }) {
    return ReadingItem(
      id: id ?? this.id,
      code: code ?? this.code,
      source: source ?? this.source,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      codeType: classification?.codeType ?? codeType ?? this.codeType,
      classificationStatus: classification?.classificationStatus ??
          classificationStatus ??
          this.classificationStatus,
      classificationCandidates: classification?.classificationCandidates ??
          classificationCandidates ??
          this.classificationCandidates,
      detailsPayload: classification?.detailsPayload ??
          detailsPayload ??
          this.detailsPayload,
      metadataPayload: metadataPayload ?? this.metadataPayload,
      schemaVersion:
          classification?.schemaVersion ?? schemaVersion ?? this.schemaVersion,
    );
  }
}
