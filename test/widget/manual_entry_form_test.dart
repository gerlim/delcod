import 'package:barcode_app/features/readings/presentation/manual_entry_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('permite envio manual de um código', (tester) async {
    String? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ManualEntryForm(
            onSubmit: (value) => submitted = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '7891234567890');
    await tester.tap(find.text('Adicionar código'));
    await tester.pump();

    expect(submitted, '7891234567890');
  });
}
