import 'package:barcode_app/features/inventory/data/inventory_repository.dart';
import 'package:barcode_app/features/inventory/domain/inventory_audit_result.dart';
import 'package:barcode_app/features/inventory/domain/inventory_import_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('createAuditFromImport archives previous active audit', () async {
    final dataSource = InMemoryInventoryRemoteDataSource();
    final repository = InventoryRepository(dataSource: dataSource);

    final first = await repository.createAuditFromImport(
      title: 'Primeira auditoria',
      sourceFilename: 'primeira.xlsx',
      drafts: [_draft(barcode: '100')],
    );
    final second = await repository.createAuditFromImport(
      title: 'Segunda auditoria',
      sourceFilename: 'segunda.xlsx',
      drafts: [_draft(barcode: '200')],
    );

    expect(first.isActive, isTrue);
    expect(second.isActive, isTrue);
    expect((await repository.fetchActiveAudit())?.id, second.id);
    expect(dataSource.auditById(first.id)?.isActive, isFalse);
  });

  test('findItemByBarcode uses active audit item barcode', () async {
    final repository = InventoryRepository(
      dataSource: InMemoryInventoryRemoteDataSource(),
    );
    final audit = await repository.createAuditFromImport(
      title: 'Auditoria',
      sourceFilename: 'inventario.xlsx',
      drafts: [_draft(barcode: '789001')],
    );

    final item = await repository.findItemByBarcode(audit.id, ' 789001 ');

    expect(item?.barcode, '789001');
  });

  test('saveResult blocks duplicate scanned barcode', () async {
    final repository = InventoryRepository(
      dataSource: InMemoryInventoryRemoteDataSource(),
    );
    final audit = await repository.createAuditFromImport(
      title: 'Auditoria',
      sourceFilename: 'inventario.xlsx',
      drafts: [_draft(barcode: '789001')],
    );
    final item = await repository.findItemByBarcode(audit.id, '789001');

    await repository.saveResult(
      InventoryAuditResult.correct(
        id: 'result-1',
        auditId: audit.id,
        inventoryItemId: item!.id,
        scannedBarcode: '789001',
        scannedAt: DateTime.utc(2026, 5, 14),
      ),
    );

    expect(
      () => repository.saveResult(
        InventoryAuditResult.incorrect(
          id: 'result-2',
          auditId: audit.id,
          inventoryItemId: item.id,
          scannedBarcode: '789001',
          discrepancyFields: const {InventoryDiscrepancyField.weight},
          scannedAt: DateTime.utc(2026, 5, 14),
        ),
      ),
      throwsA(isA<DuplicateInventoryAuditResultException>()),
    );
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
