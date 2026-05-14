import 'package:barcode_app/features/inventory/data/inventory_remote_contract.dart';
import 'package:barcode_app/features/inventory/domain/inventory_audit.dart';

abstract final class InventoryAuditMapper {
  static Map<String, dynamic> toJson(InventoryAudit audit) {
    return {
      InventoryAuditsRemoteContract.id: audit.id,
      InventoryAuditsRemoteContract.title: audit.title,
      InventoryAuditsRemoteContract.status: audit.status.remoteValue,
      InventoryAuditsRemoteContract.importedAt:
          audit.importedAt.toIso8601String(),
      InventoryAuditsRemoteContract.itemCount: audit.itemCount,
      InventoryAuditsRemoteContract.sourceFilename: audit.sourceFilename,
      InventoryAuditsRemoteContract.createdAt: audit.createdAt.toIso8601String(),
      InventoryAuditsRemoteContract.updatedAt: audit.updatedAt.toIso8601String(),
    };
  }

  static InventoryAudit fromJson(Map<String, dynamic> json) {
    return InventoryAudit(
      id: json[InventoryAuditsRemoteContract.id] as String,
      title: json[InventoryAuditsRemoteContract.title] as String,
      status: _statusFromRemote(
        json[InventoryAuditsRemoteContract.status] as String,
      ),
      importedAt: DateTime.parse(
        json[InventoryAuditsRemoteContract.importedAt] as String,
      ).toUtc(),
      itemCount: json[InventoryAuditsRemoteContract.itemCount] as int,
      sourceFilename:
          json[InventoryAuditsRemoteContract.sourceFilename] as String? ?? '',
      createdAt: DateTime.parse(
        json[InventoryAuditsRemoteContract.createdAt] as String,
      ).toUtc(),
      updatedAt: DateTime.parse(
        json[InventoryAuditsRemoteContract.updatedAt] as String,
      ).toUtc(),
    );
  }

  static InventoryAuditStatus _statusFromRemote(String value) {
    return switch (value) {
      'active' => InventoryAuditStatus.active,
      'archived' => InventoryAuditStatus.archived,
      _ => throw FormatException('Status de auditoria invalido: $value'),
    };
  }
}

extension InventoryAuditStatusRemote on InventoryAuditStatus {
  String get remoteValue {
    return switch (this) {
      InventoryAuditStatus.active => 'active',
      InventoryAuditStatus.archived => 'archived',
    };
  }
}
