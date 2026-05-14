import 'package:barcode_app/features/inventory/application/inventory_audit_controller.dart';
import 'package:barcode_app/features/inventory/domain/inventory_audit.dart';
import 'package:barcode_app/features/inventory/domain/inventory_audit_result.dart';
import 'package:barcode_app/features/inventory/domain/inventory_item.dart';
import 'package:barcode_app/features/inventory/presentation/inventory_scan_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows read-only item fields and decision buttons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InventoryScanPage(
          state: _foundState(),
        ),
      ),
    );

    expect(find.text('Empresa'), findsOneWidget);
    expect(find.text('Bora Embalagens'), findsOneWidget);
    expect(find.text('Codigo'), findsOneWidget);
    expect(find.text('BOB-001'), findsOneWidget);
    expect(find.text('Descricao'), findsOneWidget);
    expect(find.text('Papel kraft'), findsOneWidget);
    expect(find.text('Codigo de barras'), findsOneWidget);
    expect(find.text('789001'), findsWidgets);
    expect(find.text('Peso'), findsOneWidget);
    expect(find.text('482,5'), findsOneWidget);
    expect(find.text('Armazem'), findsOneWidget);
    expect(find.text('05'), findsOneWidget);
    expect(find.text('Correto'), findsOneWidget);
    expect(find.text('Incorreto'), findsOneWidget);
  });

  testWidgets('shows discrepancy fields and optional note', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InventoryScanPage(
          state: _foundState(),
        ),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -320));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Incorreto'));
    await tester.pumpAndSettle();

    expect(find.text('Campos divergentes'), findsOneWidget);
    expect(find.text('Peso'), findsWidgets);
    expect(find.text('Observacao opcional'), findsOneWidget);
  });

  testWidgets('blocks already audited barcode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InventoryScanPage(
          state: _foundState(
            status: InventoryAuditFlowStatus.alreadyAudited,
            existingResult: InventoryAuditResult.correct(
              id: 'result-1',
              auditId: 'audit-1',
              inventoryItemId: 'item-1',
              scannedBarcode: '789001',
              scannedAt: DateTime.utc(2026, 5, 14),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Essa bobina ja foi auditada'), findsOneWidget);
    expect(find.text('Correto'), findsNothing);
  });

  testWidgets('shows audited barcodes with result status', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InventoryScanPage(
          state: _foundState(
            auditedResults: [
              InventoryAuditResult.correct(
                id: 'result-1',
                auditId: 'audit-1',
                inventoryItemId: 'item-1',
                scannedBarcode: '789001',
                scannedAt: DateTime.utc(2026, 5, 14),
              ),
              InventoryAuditResult.notFound(
                id: 'result-2',
                auditId: 'audit-1',
                scannedBarcode: '999999',
                scannedAt: DateTime.utc(2026, 5, 14, 1),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();

    expect(find.text('Codigos lidos'), findsOneWidget);
    expect(find.text('789001'), findsWidgets);
    expect(find.text('Correto'), findsWidgets);
    expect(find.text('999999'), findsOneWidget);
    expect(find.text('Nao esta no banco'), findsOneWidget);
  });
}

InventoryAuditFlowState _foundState({
  InventoryAuditFlowStatus status = InventoryAuditFlowStatus.found,
  InventoryAuditResult? existingResult,
  List<InventoryAuditResult> auditedResults = const [],
}) {
  return InventoryAuditFlowState(
    status: status,
    activeAudit: InventoryAudit(
      id: 'audit-1',
      title: 'Auditoria',
      status: InventoryAuditStatus.active,
      importedAt: DateTime.utc(2026, 5, 14),
      itemCount: 1,
      sourceFilename: 'inventario.xlsx',
      createdAt: DateTime.utc(2026, 5, 14),
      updatedAt: DateTime.utc(2026, 5, 14),
    ),
    scannedBarcode: '789001',
    item: const InventoryItem(
      id: 'item-1',
      auditId: 'audit-1',
      companyName: 'Bora Embalagens',
      bobbinCode: 'BOB-001',
      itemDescription: 'Papel kraft',
      barcode: '789001',
      weight: '482,5',
      warehouse: '05',
      rowNumber: 2,
    ),
    existingResult: existingResult,
    auditedResults: auditedResults,
  );
}
