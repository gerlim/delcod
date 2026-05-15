import 'package:barcode_app/app/app.dart';
import 'package:barcode_app/core/platform/platform_capabilities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('abre a tela principal de auditoria de inventario', (
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
        child: const BarcodeApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Auditoria de inventario'), findsOneWidget);
    expect(find.text('Importar XLS/XLSX'), findsOneWidget);
  });
}
