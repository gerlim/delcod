import 'dart:typed_data';

import 'package:barcode_app/features/inventory/application/inventory_import_controller.dart';
import 'package:barcode_app/features/inventory/data/inventory_import_service.dart';
import 'package:barcode_app/features/inventory/data/inventory_repository.dart';
import 'package:barcode_app/features/inventory/domain/inventory_audit_result.dart';
import 'package:barcode_app/features/inventory/domain/inventory_import_models.dart';
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
        [
          'Empresa',
          'Codigo',
          'Descricao',
          'Codigo de Barras',
          'Peso',
          'Armazem'
        ],
        ['Bora Embalagens', 'BOB-001', 'Papel kraft', '789001', '482,5', '05'],
      ]),
    );

    expect(state.importedCount, 1);
    expect(state.activeAuditId, isNotNull);
    expect(state.errors, isEmpty);
    expect((await repository.fetchActiveAudit())?.sourceFilename,
        'inventario.xlsx');
  });

  test('loads active audit from repository with status counts', () async {
    final repository = InventoryRepository(
      dataSource: InMemoryInventoryRemoteDataSource(),
    );
    final audit = await repository.createAuditFromImport(
      title: 'Auditoria',
      sourceFilename: 'saldo.xlsx',
      drafts: [
        _draft(barcode: '789001'),
        _draft(barcode: '789002'),
      ],
    );
    final item = await repository.findItemByBarcode(audit.id, '789001');
    await repository.saveResult(
      InventoryAuditResult.correct(
        id: 'result-1',
        auditId: audit.id,
        inventoryItemId: item!.id,
        scannedBarcode: item.barcode,
        scannedAt: DateTime.utc(2026, 5, 15),
      ),
    );
    final controller = InventoryImportController(
      importService: const InventoryImportService(),
      repository: repository,
    );

    final state = await controller.loadActiveAudit();

    expect(state.filename, 'saldo.xlsx');
    expect(state.importedCount, 2);
    expect(state.activeAuditId, audit.id);
    expect(state.correctCount, 1);
    expect(state.pendingCount, 1);
  });

  test('archives active audit for web testing', () async {
    final repository = InventoryRepository(
      dataSource: InMemoryInventoryRemoteDataSource(),
    );
    await repository.createAuditFromImport(
      title: 'Auditoria',
      sourceFilename: 'saldo.xlsx',
      drafts: [_draft(barcode: '789001')],
    );
    final controller = InventoryImportController(
      importService: const InventoryImportService(),
      repository: repository,
    );

    final state = await controller.archiveActiveAudit();

    expect(state.activeAuditId, isNull);
    expect(state.importedCount, 0);
    expect(await repository.fetchActiveAudit(), isNull);
  });

  test('updates imported item for web testing', () async {
    final repository = InventoryRepository(
      dataSource: InMemoryInventoryRemoteDataSource(),
    );
    final audit = await repository.createAuditFromImport(
      title: 'Auditoria',
      sourceFilename: 'saldo.xlsx',
      drafts: [_draft(barcode: '789001')],
    );
    final item = await repository.findItemByBarcode(audit.id, '789001');
    final controller = InventoryImportController(
      importService: const InventoryImportService(),
      repository: repository,
    );

    final state = await controller.updateItem(
      item!.copyWith(weight: '500,0', warehouse: 'PPI'),
    );

    final updated = await repository.findItemByBarcode(audit.id, '789001');
    expect(updated?.weight, '500,0');
    expect(updated?.warehouse, 'PPI');
    expect(state.importedItems.first.weight, '500,0');
  });

  test('creates audit ignoring duplicated barcodes', () async {
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

    expect(state.importedCount, 1);
    expect(state.errors, isEmpty);
    expect(await repository.fetchActiveAudit(), isNotNull);
  });
}

InventoryItemDraft _draft({required String barcode}) {
  return InventoryItemDraft(
    companyName: 'Bora Embalagens',
    bobbinCode: 'BOB-$barcode',
    itemDescription: 'Papel kraft',
    barcode: barcode,
    weight: '482,5',
    warehouse: '05',
    rowNumber: 2,
    rawPayload: const {},
  );
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
