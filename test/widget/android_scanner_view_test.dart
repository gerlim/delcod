import 'package:barcode_app/features/readings/presentation/android_scanner_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  testWidgets('mostra o atalho do scanner em plataformas suportadas',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AndroidScannerView(
            onDetected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Abrir scanner'), findsOneWidget);
  });

  testWidgets('abre o scanner ocupando a altura util da tela', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AndroidScannerView(
            onDetected: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir scanner'));
    await tester.pumpAndSettle();

    final scannerFinder = find.byType(MobileScanner);
    expect(scannerFinder, findsOneWidget);

    final scannerHeight = tester.getSize(scannerFinder).height;
    expect(scannerHeight, greaterThanOrEqualTo(860));
  });
}
