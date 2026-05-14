import 'dart:typed_data';

import 'package:barcode_app/features/inventory/application/inventory_import_controller.dart';
import 'package:barcode_app/features/inventory/data/inventory_import_service.dart';
import 'package:barcode_app/features/inventory/data/inventory_repository.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('imports valid xlsx and creates active audit', () async {
    final repository = InventoryRepository(
      dataSource: InMemoryInventoryRemoteDataSource(),
    );
    final controller = InventoryImportController(
      importService: const InventoryImportService(),
      repository: repository,
    );

    final state = await controller.importXlsx(
      filename: 'inventario.xlsx',
      bytes: _buildWorkbook([
        ['Empresa', 'Codigo', 'Descricao', 'Codigo de Barras', 'Peso', 'Armazem'],
        ['Bora Embalagens', 'BOB-001', 'Papel kraft', '789001', '482,5', '05'],
      ]),
    );

    expect(state.importedCount, 1);
    expect(state.activeAuditId, isNotNull);
    expect(state.errors, isEmpty);
    expect((await repository.fetchActiveAudit())?.sourceFilename, 'inventario.xlsx');
  });

  test('does not create audit when xlsx has duplicate barcodes', () async {
    final repository = InventoryRepository(
      dataSource: InMemoryInventoryRemoteDataSource(),
    );
    final controller = InventoryImportController(
      importService: const InventoryImportService(),
      repository: repository,
    );

    final state = await controller.importXlsx(
      filename: 'inventario.xlsx',
      bytes: _buildWorkbook([
        ['Empresa', 'Codigo', 'Descricao', 'Codigo de Barras', 'Peso', 'Armazem'],
        ['Bora Embalagens', 'BOB-001', 'Papel kraft', '789001', '482,5', '05'],
        ['ABN Embalagens', 'BOB-002', 'Papel branco', '789001', '510', 'GLR'],
      ]),
    );

    expect(state.importedCount, 0);
    expect(state.errors, isNotEmpty);
    expect(await repository.fetchActiveAudit(), isNull);
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
  return Uint8List.fromList(excel.encode()!);
}
