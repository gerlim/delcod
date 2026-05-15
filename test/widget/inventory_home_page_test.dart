import 'package:barcode_app/core/platform/platform_capabilities.dart';
import 'package:barcode_app/features/inventory/application/inventory_audit_controller.dart';
import 'package:barcode_app/features/inventory/presentation/inventory_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows web import workflow when camera scanning is unsupported', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          platformCapabilitiesProvider.overrideWithValue(
            const PlatformCapabilities(
              supportsCameraScanning: false,
              supportsManualEntry: true,
            ),
          ),
        ],
        child: const MaterialApp(home: InventoryHomePage()),
      ),
    );

    expect(find.text('Auditoria de inventario'), findsOneWidget);
    expect(find.text('Importar XLS/XLSX'), findsOneWidget);
  });

  testWidgets('shows scan workflow when camera scanning is supported', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          platformCapabilitiesProvider.overrideWithValue(
            const PlatformCapabilities(
              supportsCameraScanning: true,
              supportsManualEntry: true,
            ),
          ),
          inventoryAuditControllerProvider.overrideWith(
            () => _StaticInventoryAuditNotifier(
              const InventoryAuditFlowState.ready(),
            ),
          ),
        ],
        child: const MaterialApp(home: InventoryHomePage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Auditar bobina'), findsOneWidget);
    expect(find.text('Codigo de barras manual'), findsOneWidget);
  });
}

class _StaticInventoryAuditNotifier extends InventoryAuditNotifier {
  _StaticInventoryAuditNotifier(this._state);

  final InventoryAuditFlowState _state;

  @override
  Future<InventoryAuditFlowState> build() async => _state;
}
