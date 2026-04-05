import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/bobbin_inventory_record.dart';

class ReadingsListFilter {
  const ReadingsListFilter._();

  static List<ReadingItem> apply(
    List<ReadingItem> items,
    String query,
  ) {
    final normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty) {
      return items;
    }

    return items.where((item) {
      final record = BobbinInventoryRecord.fromItem(item);
      final lot = normalize(record.lot);
      final warehouseCode = normalize(record.warehouseCode ?? '');
      return lot.contains(normalizedQuery) ||
          warehouseCode.contains(normalizedQuery);
    }).toList(growable: false);
  }

  static String normalize(String value) {
    return value.trim().toLowerCase();
  }
}
