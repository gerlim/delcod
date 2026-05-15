import 'package:barcode_app/core/platform/platform_capabilities.dart';
import 'package:barcode_app/features/app_update/application/app_update_controller.dart';
import 'package:barcode_app/features/app_update/domain/app_update_manifest.dart';
import 'package:barcode_app/features/inventory/application/inventory_import_controller.dart';
import 'package:barcode_app/features/inventory/domain/inventory_import_models.dart';
import 'package:barcode_app/features/inventory/domain/inventory_item.dart';
import 'package:barcode_app/features/inventory/presentation/inventory_import_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows import, active summary, export, and history sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
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
      ),
    );

    expect(find.text('Importar XLS/XLSX'), findsOneWidget);
    expect(find.text('Auditoria ativa'), findsOneWidget);
    expect(find.text('Exportar resultado'), findsOneWidget);
    expect(find.text('Historico de auditorias'), findsOneWidget);
  });

  testWidgets('shows validation errors', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
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
      ),
    );

    expect(find.textContaining('Codigo de barras duplicado'), findsOneWidget);
  });

  testWidgets('shows update banner in inventory UI on Android', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          platformCapabilitiesProvider.overrideWithValue(
            const PlatformCapabilities(
              supportsCameraScanning: true,
              supportsManualEntry: true,
            ),
          ),
          appUpdateControllerProvider.overrideWith(
            () => _StaticAppUpdateController(
              AppUpdateState(
                status: AppUpdateStatus.available,
                currentVersionName: '1.1.3',
                currentVersionCode: 9,
                availableManifest: AppUpdateManifest.fromJson(
                  {
                    'versionName': '1.1.4',
                    'versionCode': 10,
                    'apkUrl': 'https://updates.delcod.app/DelCod-10.apk',
                  },
                ),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: InventoryImportPage(
            state: InventoryImportState(
              filename: null,
              isLoading: false,
              importedCount: 0,
              activeAuditId: null,
              errors: [],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Nova versao disponivel'), findsOneWidget);
    expect(find.text('Atualizar agora'), findsOneWidget);
  });

  testWidgets('shows web maintenance action when enabled', (tester) async {
    var archived = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: InventoryImportPage(
            showWebMaintenanceActions: true,
            onArchiveActiveAuditPressed: () => archived = true,
            state: const InventoryImportState(
              filename: 'saldo.xlsx',
              isLoading: false,
              importedCount: 12,
              activeAuditId: 'audit-1',
              errors: [],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Arquivo: saldo.xlsx'), findsOneWidget);
    expect(find.text('Apagar auditoria'), findsOneWidget);

    await tester.tap(find.text('Apagar auditoria'));
    await tester.pumpAndSettle();

    expect(archived, isTrue);
  });

  testWidgets('opens web item editor when enabled', (tester) async {
    InventoryItem? savedItem;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: InventoryImportPage(
            showWebMaintenanceActions: true,
            onSaveImportedItem: (item) async => savedItem = item,
            state: const InventoryImportState(
              filename: 'saldo.xlsx',
              isLoading: false,
              importedCount: 1,
              activeAuditId: 'audit-1',
              importedItems: [
                InventoryItem(
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
              ],
              errors: [],
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Itens importados'), findsOneWidget);
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Peso'),
      '500,0',
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(savedItem?.weight, '500,0');
  });
}

class _StaticAppUpdateController extends AppUpdateController {
  _StaticAppUpdateController(this._state);

  final AppUpdateState _state;

  @override
  AppUpdateState build() => _state;
}
