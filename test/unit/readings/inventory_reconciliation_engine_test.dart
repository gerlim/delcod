import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/inventory_reconciliation.dart';
import 'package:barcode_app/features/readings/domain/inventory_reconciliation_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = InventoryReconciliationEngine();

  test('marca lote importado sem leitura fisica como faltante', () {
    final snapshot = engine.reconcile([
      _item(
        id: 'import-1',
        lot: '001126023205936309',
        source: 'import',
        warehouseCode: '05',
      ),
    ]);

    final entry = snapshot.byLot['001126023205936309'];
    expect(entry, isNotNull);
    expect(entry!.presenceStatus, InventoryPresenceStatus.expectedOnly);
    expect(entry.warehouseStatus, InventoryWarehouseStatus.notApplicable);
    expect(snapshot.missingLotsCount, 1);
  });

  test('marca lote encontrado quando importacao e leitura batem no mesmo armazem', () {
    final snapshot = engine.reconcile([
      _item(
        id: 'import-1',
        lot: '001126023205936309',
        source: 'import',
        warehouseCode: '05',
      ),
      _item(
        id: 'camera-1',
        lot: '001126023205936309',
        source: 'camera',
        warehouseCode: '05',
      ),
    ]);

    final entry = snapshot.byLot['001126023205936309'];
    expect(entry, isNotNull);
    expect(entry!.presenceStatus, InventoryPresenceStatus.matched);
    expect(entry.warehouseStatus, InventoryWarehouseStatus.aligned);
    expect(snapshot.matchedLotsCount, 1);
    expect(snapshot.warehouseMismatchLotsCount, 0);
  });

  test('marca divergencia quando leitura e base possuem armazens diferentes', () {
    final snapshot = engine.reconcile([
      _item(
        id: 'import-1',
        lot: '001126023205936309',
        source: 'import',
        warehouseCode: '05',
      ),
      _item(
        id: 'camera-1',
        lot: '001126023205936309',
        source: 'camera',
        warehouseCode: 'GLR',
      ),
    ]);

    final entry = snapshot.byLot['001126023205936309'];
    expect(entry, isNotNull);
    expect(entry!.presenceStatus, InventoryPresenceStatus.matched);
    expect(entry.warehouseStatus, InventoryWarehouseStatus.mismatch);
    expect(snapshot.warehouseMismatchLotsCount, 1);
  });

  test('marca lote lido fora da base como excedente', () {
    final snapshot = engine.reconcile([
      _item(
        id: 'manual-1',
        lot: '001126023205936309',
        source: 'manual',
        warehouseCode: 'PPI',
      ),
    ]);

    final entry = snapshot.byLot['001126023205936309'];
    expect(entry, isNotNull);
    expect(entry!.presenceStatus, InventoryPresenceStatus.countedOnly);
    expect(entry.warehouseStatus, InventoryWarehouseStatus.notApplicable);
    expect(snapshot.unexpectedLotsCount, 1);
  });

  test('mantem status de armazem desconhecido quando um dos lados ainda esta pendente', () {
    final snapshot = engine.reconcile([
      _item(
        id: 'import-1',
        lot: '001126023205936309',
        source: 'import',
        warehouseCode: '05',
      ),
      _item(
        id: 'camera-1',
        lot: '001126023205936309',
        source: 'camera',
      ),
    ]);

    final entry = snapshot.byLot['001126023205936309'];
    expect(entry, isNotNull);
    expect(entry!.presenceStatus, InventoryPresenceStatus.matched);
    expect(entry.warehouseStatus, InventoryWarehouseStatus.unknown);
    expect(snapshot.unknownWarehouseLotsCount, 1);
  });
}

ReadingItem _item({
  required String id,
  required String lot,
  required String source,
  String? warehouseCode,
}) {
  return ReadingItem(
    id: id,
    code: lot,
    source: source,
    updatedAt: DateTime.parse('2026-04-01T12:00:00Z'),
    deletedAt: null,
    deviceId: 'device-a',
    metadataPayload: {
      'bobbin_lot': lot,
      if (warehouseCode != null) 'warehouse_code': warehouseCode,
    },
  );
}
