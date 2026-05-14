import 'package:barcode_app/features/inventory/data/inventory_remote_contract.dart';
import 'package:barcode_app/features/inventory/domain/inventory_item.dart';

abstract final class InventoryItemMapper {
  static Map<String, dynamic> toJson(InventoryItem item) {
    return {
      InventoryItemsRemoteContract.id: item.id,
      InventoryItemsRemoteContract.auditId: item.auditId,
      InventoryItemsRemoteContract.companyName: item.companyName,
      InventoryItemsRemoteContract.bobbinCode: item.bobbinCode,
      InventoryItemsRemoteContract.itemDescription: item.itemDescription,
      InventoryItemsRemoteContract.barcode: item.barcode,
      InventoryItemsRemoteContract.weight: item.weight,
      InventoryItemsRemoteContract.warehouse: item.warehouse,
      InventoryItemsRemoteContract.rowNumber: item.rowNumber,
      InventoryItemsRemoteContract.rawPayload: item.rawPayload,
    };
  }

  static InventoryItem fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json[InventoryItemsRemoteContract.id] as String,
      auditId: json[InventoryItemsRemoteContract.auditId] as String,
      companyName: json[InventoryItemsRemoteContract.companyName] as String,
      bobbinCode: json[InventoryItemsRemoteContract.bobbinCode] as String? ?? '',
      itemDescription:
          json[InventoryItemsRemoteContract.itemDescription] as String? ?? '',
      barcode: json[InventoryItemsRemoteContract.barcode] as String,
      weight: json[InventoryItemsRemoteContract.weight] as String? ?? '',
      warehouse: json[InventoryItemsRemoteContract.warehouse] as String? ?? '',
      rowNumber: json[InventoryItemsRemoteContract.rowNumber] as int,
      rawPayload: Map<String, dynamic>.from(
        json[InventoryItemsRemoteContract.rawPayload] as Map? ??
            const <String, dynamic>{},
      ),
    );
  }
}
