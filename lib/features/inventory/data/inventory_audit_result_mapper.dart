import 'package:barcode_app/features/inventory/data/inventory_remote_contract.dart';
import 'package:barcode_app/features/inventory/domain/inventory_audit_result.dart';

abstract final class InventoryAuditResultMapper {
  static Map<String, dynamic> toJson(InventoryAuditResult result) {
    return {
      InventoryAuditResultsRemoteContract.id: result.id,
      InventoryAuditResultsRemoteContract.auditId: result.auditId,
      InventoryAuditResultsRemoteContract.inventoryItemId:
          result.inventoryItemId,
      InventoryAuditResultsRemoteContract.scannedBarcode: result.scannedBarcode,
      InventoryAuditResultsRemoteContract.status: result.status.remoteValue,
      InventoryAuditResultsRemoteContract.discrepancyFields: result
          .discrepancyFields
          .map((field) => field.remoteValue)
          .toList(growable: false),
      InventoryAuditResultsRemoteContract.note: result.note,
      InventoryAuditResultsRemoteContract.scannedAt:
          result.scannedAt.toIso8601String(),
    };
  }

  static InventoryAuditResult fromJson(Map<String, dynamic> json) {
    return InventoryAuditResult(
      id: json[InventoryAuditResultsRemoteContract.id] as String,
      auditId: json[InventoryAuditResultsRemoteContract.auditId] as String,
      inventoryItemId:
          json[InventoryAuditResultsRemoteContract.inventoryItemId] as String?,
      scannedBarcode:
          json[InventoryAuditResultsRemoteContract.scannedBarcode] as String,
      status: _statusFromRemote(
        json[InventoryAuditResultsRemoteContract.status] as String,
      ),
      discrepancyFields: Set.unmodifiable(
        (json[InventoryAuditResultsRemoteContract.discrepancyFields]
                    as List? ??
                const [])
            .map((value) => _fieldFromRemote(value as String)),
      ),
      note: json[InventoryAuditResultsRemoteContract.note] as String?,
      scannedAt: DateTime.parse(
        json[InventoryAuditResultsRemoteContract.scannedAt] as String,
      ).toUtc(),
    );
  }

  static InventoryAuditResultStatus _statusFromRemote(String value) {
    return switch (value) {
      'correct' => InventoryAuditResultStatus.correct,
      'incorrect' => InventoryAuditResultStatus.incorrect,
      'not_found' => InventoryAuditResultStatus.notFound,
      _ => throw FormatException('Status de auditoria invalido: $value'),
    };
  }

  static InventoryDiscrepancyField _fieldFromRemote(String value) {
    for (final field in InventoryDiscrepancyField.values) {
      if (field.remoteValue == value) {
        return field;
      }
    }
    throw FormatException('Campo divergente invalido: $value');
  }
}

extension InventoryAuditResultStatusRemote on InventoryAuditResultStatus {
  String get remoteValue {
    return switch (this) {
      InventoryAuditResultStatus.correct => 'correct',
      InventoryAuditResultStatus.incorrect => 'incorrect',
      InventoryAuditResultStatus.notFound => 'not_found',
    };
  }
}

extension InventoryDiscrepancyFieldRemote on InventoryDiscrepancyField {
  String get remoteValue {
    return switch (this) {
      InventoryDiscrepancyField.company => 'company',
      InventoryDiscrepancyField.bobbinCode => 'bobbin_code',
      InventoryDiscrepancyField.description => 'description',
      InventoryDiscrepancyField.barcode => 'barcode',
      InventoryDiscrepancyField.weight => 'weight',
      InventoryDiscrepancyField.warehouse => 'warehouse',
    };
  }
}
