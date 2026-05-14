import 'package:barcode_app/features/inventory/application/inventory_import_controller.dart';
import 'package:barcode_app/features/inventory/domain/inventory_import_models.dart';
import 'package:barcode_app/features/inventory/presentation/inventory_import_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows import, active summary, export, and history sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: InventoryImportPage(
          state: InventoryImportState(
            filename: 'inventario.xlsx',
            isLoading: false,
            importedCount: 120,
            activeAuditId: 'audit-1',
            errors: [],
          ),
        ),
      ),
    );

    expect(find.text('Importar XLSX'), findsOneWidget);
    expect(find.text('Auditoria ativa'), findsOneWidget);
    expect(find.text('Exportar resultado'), findsOneWidget);
    expect(find.text('Historico de auditorias'), findsOneWidget);
  });

  testWidgets('shows validation errors', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: InventoryImportPage(
          state: InventoryImportState(
            filename: 'inventario.xlsx',
            isLoading: false,
            importedCount: 0,
            activeAuditId: null,
            errors: [
              InventoryImportError(
                message: 'Codigo de barras duplicado: 789001',
                rowNumber: 3,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining('Codigo de barras duplicado'), findsOneWidget);
  });
}
