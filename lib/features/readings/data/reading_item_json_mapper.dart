import 'package:barcode_app/features/readings/data/readings_remote_contract.dart';
import 'package:barcode_app/features/readings/domain/reading_classification.dart';
import 'package:barcode_app/features/readings/domain/reading_item.dart';

abstract final class ReadingItemJsonMapper {
  static Map<String, dynamic> toJson(ReadingItem item) {
    return <String, dynamic>{
      ReadingsRemoteContract.id: item.id,
      ReadingsRemoteContract.code: item.code,
      ReadingsRemoteContract.source: item.source,
      ReadingsRemoteContract.updatedAt: item.updatedAt.toIso8601String(),
      ReadingsRemoteContract.deletedAt: item.deletedAt?.toIso8601String(),
      ReadingsRemoteContract.deviceId: item.deviceId,
      ...ReadingClassification.stored(
        codeType: item.codeType,
        classificationStatus: item.classificationStatus,
        classificationCandidates: item.classificationCandidates,
        detailsPayload: item.detailsPayload,
        schemaVersion: item.schemaVersion,
      ).toJson(),
      ReadingsRemoteContract.metadataPayload: item.metadataPayload,
    };
  }

  static ReadingItem fromJson(Map<String, dynamic> json) {
    return ReadingItem(
      id: json[ReadingsRemoteContract.id] as String,
      code: json[ReadingsRemoteContract.code] as String,
      source: json[ReadingsRemoteContract.source] as String? ?? 'manual',
      updatedAt:
          DateTime.parse(json[ReadingsRemoteContract.updatedAt] as String)
              .toUtc(),
      deletedAt: json[ReadingsRemoteContract.deletedAt] == null
          ? null
          : DateTime.parse(json[ReadingsRemoteContract.deletedAt] as String)
              .toUtc(),
      deviceId:
          json[ReadingsRemoteContract.deviceId] as String? ?? 'unknown-device',
      classification: ReadingClassification.fromJson(json),
      metadataPayload: _readMetadataPayload(
        json[ReadingsRemoteContract.metadataPayload],
      ),
    );
  }

  static Map<String, dynamic>? _readMetadataPayload(Object? rawPayload) {
    if (rawPayload is Map<String, dynamic>) {
      return rawPayload;
    }
    if (rawPayload is Map) {
      return Map<String, dynamic>.from(rawPayload);
    }
    return null;
  }
}
