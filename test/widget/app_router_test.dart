import 'package:barcode_app/app/router/app_router.dart';
import 'package:barcode_app/core/platform/platform_capabilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('abre direto na tela principal de inventario', (tester) async {
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
        child: MaterialApp.router(
          routerConfig: buildRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Auditoria de inventario'), findsOneWidget);
    expect(find.text('Importar XLS/XLSX'), findsOneWidget);
  });
}
