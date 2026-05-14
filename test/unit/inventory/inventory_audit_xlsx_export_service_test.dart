import 'package:barcode_app/features/inventory/export/inventory_audit_xlsx_export_service.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generates workbook with expected audit result sheets', () {
    final bytes = const InventoryAuditXlsxExportService().buildFile(
      const InventoryAuditExport(
        correct: [],
        incorrect: [],
        notFound: [],
        pending: [],
      ),
    );

    final workbook = Excel.decodeBytes(bytes);

    expect(workbook.tables.keys, contains('Corretos'));
    expect(workbook.tables.keys, contains('Incorretos'));
    expect(workbook.tables.keys, contains('Nao encontrados'));
    expect(workbook.tables.keys, contains('Pendentes'));
  });
}
