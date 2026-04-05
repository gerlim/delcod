import 'package:barcode_app/features/export/domain/export_readings_payload.dart';
import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/bobbin_inventory_record.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final readingsExportPayloadBuilderProvider =
    Provider<ReadingsExportPayloadBuilder>(
  (ref) => const ReadingsExportPayloadBuilder(),
);

class ReadingsExportPayloadBuilder {
  const ReadingsExportPayloadBuilder();

  ExportReadingsPayload build({
    required String title,
    required List<ReadingItem> items,
  }) {
    return ExportReadingsPayload(
      title: title,
      rows: items
          .map((item) {
            final record = BobbinInventoryRecord.fromItem(item);
            return ExportReadingRow(
              lot: record.lot,
              warehouseCode: record.warehouseCode,
              companyName: record.companyName,
              isPendingWarehouse: !record.hasWarehouseAllocated,
            );
          })
          .toList(growable: false),
    );
  }
}
