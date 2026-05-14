import 'dart:typed_data';

import 'package:barcode_app/features/inventory/data/inventory_import_service.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('imports xlsx inventory with mixed companies', () {
    const service = InventoryImportService();
    final result = service.parseXlsx(
      filename: 'inventario.xlsx',
      bytes: _buildWorkbook([
        [
          'Empresa',
          'Codigo',
          'Descricao',
          'Codigo de Barras',
          'Peso',
          'Armazem'
        ],
        [
          'Bora Embalagens',
          'BOB-001',
          'Papel kraft',
          '789001',
          '482,5',
          '05',
        ],
        [
          'ABN Embalagens',
          'BOB-002',
          'Papel branco',
          '789002',
          '510',
          'GLR',
        ],
      ]),
    );

    expect(result.isValid, isTrue);
    expect(result.items, hasLength(2));
    expect(result.items.first.companyName, 'Bora Embalagens');
    expect(result.items.last.companyName, 'ABN Embalagens');
    expect(result.items.first.barcode, '789001');
    expect(result.items.first.weight, '482,5');
  });

  test('rejects duplicate barcodes in the same import', () {
    const service = InventoryImportService();
    final result = service.parseXlsx(
      filename: 'inventario.xlsx',
      bytes: _buildWorkbook([
        [
          'Empresa',
          'Codigo',
          'Descricao',
          'Codigo de Barras',
          'Peso',
          'Armazem'
        ],
        ['Bora Embalagens', 'BOB-001', 'Papel kraft', '789001', '482,5', '05'],
        ['ABN Embalagens', 'BOB-002', 'Papel branco', '789001', '510', 'GLR'],
      ]),
    );

    expect(result.isValid, isFalse);
    expect(result.errors.single.message, contains('789001'));
  });
}

Uint8List _buildWorkbook(List<List<String>> rows) {
  final excel = Excel.createExcel();
  final sheet = excel['Inventario'];
  for (final row in rows) {
    sheet.appendRow(
      row.map((value) => TextCellValue(value)).toList(growable: false),
    );
  }
  final bytes = excel.encode();
  if (bytes == null) {
    throw StateError('Failed to encode test workbook.');
  }
  return Uint8List.fromList(bytes);
}
