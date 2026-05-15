import 'package:barcode_app/features/inventory/application/inventory_audit_controller.dart';
import 'package:barcode_app/features/inventory/data/inventory_repository.dart';
import 'package:barcode_app/features/inventory/domain/inventory_audit_result.dart';
import 'package:barcode_app/features/inventory/domain/inventory_import_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lookupBarcode returns found item awaiting decision', () async {
    final repository = InventoryRepository(
      dataSource: InMemoryInventoryRemoteDataSource(),
    );
    final audit = await _seedAudit(repository);
    final controller = InventoryAuditController(repository: repository);

    final state = await controller.lookupBarcode(' 789001 ');

    expect(state.status, InventoryAuditFlowStatus.found);
    expect(state.activeAudit?.id, audit.id);
    expect(state.item?.barcode, '789001');
  });

  test('lookupBarcode blocks already audited item', () async {
    final repository = InventoryRepository(
      dataSource: InMemoryInventoryRemoteDataSource(),
    );
    final audit = await _seedAudit(repository);
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
    final controller = InventoryAuditController(repository: repository);

    final state = await controller.lookupBarcode('789001');

    expect(state.status, InventoryAuditFlowStatus.alreadyAudited);
    expect(state.existingResult?.status, InventoryAuditResultStatus.correct);
  });

  test('unknown barcode can be saved as not found once', () async {
    final repository = InventoryRepository(
      dataSource: InMemoryInventoryRemoteDataSource(),
    );
    final audit = await _seedAudit(repository);
    final controller = InventoryAuditController(repository: repository);

    await controller.lookupBarcode('999999');
    final saved = await controller.markNotFound();
    final duplicateState = await controller.lookupBarcode('999999');

    expect(saved.status, InventoryAuditResultStatus.notFound);
    expect(saved.auditId, audit.id);
    expect(duplicateState.status, InventoryAuditFlowStatus.alreadyAudited);
  });

  test('markIncorrect saves discrepancy fields and optional note', () async {
    final repository = InventoryRepository(
      dataSource: InMemoryInventoryRemoteDataSource(),
    );
    await _seedAudit(repository);
    final controller = InventoryAuditController(repository: repository);

    await controller.lookupBarcode('789001');
    final saved = await controller.markIncorrect(
      fields: const {InventoryDiscrepancyField.weight},
      note: 'Peso fisico diferente',
    );

    expect(saved.status, InventoryAuditResultStatus.incorrect);
    expect(saved.discrepancyFields, contains(InventoryDiscrepancyField.weight));
    expect(saved.note, 'Peso fisico diferente');
  });

  test('keeps imported items and exposes audited results after saving', () async {
    final repository = InventoryRepository(
      dataSource: InMemoryInventoryRemoteDataSource(),
    );
    await _seedAudit(repository);
    final controller = InventoryAuditController(repository: repository);

    await controller.lookupBarcode('789001');
    final saved = await controller.markCorrect();
    final nextState = await controller.lookupBarcode('789002');

    expect(saved.status, InventoryAuditResultStatus.correct);
    expect(controller.currentState.auditedResults.map((result) {
      return result.scannedBarcode;
    }), contains('789001'));
    expect(nextState.status, InventoryAuditFlowStatus.found);
    expect(nextState.item?.barcode, '789002');
  });

  test('refreshActiveAudit clears open state after active audit is archived',
      () async {
    final repository = InventoryRepository(
      dataSource: InMemoryInventoryRemoteDataSource(),
    );
    await _seedAudit(repository);
    final controller = InventoryAuditController(repository: repository);
    final foundState = await controller.lookupBarcode('789001');

    await repository.archiveActiveAudit();
    final refreshedState = await controller.refreshActiveAudit();

    expect(foundState.status, InventoryAuditFlowStatus.found);
    expect(refreshedState.status, InventoryAuditFlowStatus.noActiveAudit);
    expect(refreshedState.activeAudit, isNull);
  });
}

Future<dynamic> _seedAudit(InventoryRepository repository) {
  return repository.createAuditFromImport(
    title: 'Auditoria',
    sourceFilename: 'inventario.xlsx',
    drafts: const [
      InventoryItemDraft(
        companyName: 'Bora Embalagens',
        bobbinCode: 'BOB-001',
        itemDescription: 'Papel kraft',
        barcode: '789001',
        weight: '482,5',
        warehouse: '05',
        rowNumber: 2,
        rawPayload: {},
      ),
      InventoryItemDraft(
        companyName: 'ABN Embalagens',
        bobbinCode: 'BOB-002',
        itemDescription: 'Papel branco',
        barcode: '789002',
        weight: '350,0',
        warehouse: '04',
        rowNumber: 3,
        rawPayload: {},
      ),
    ],
  );
}
