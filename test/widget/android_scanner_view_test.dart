import 'package:barcode_app/features/readings/presentation/android_scanner_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra o atalho do scanner em plataformas suportadas', (tester) async {
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
}
