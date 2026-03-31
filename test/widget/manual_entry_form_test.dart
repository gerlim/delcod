import 'package:barcode_app/features/readings/presentation/manual_entry_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('permite envio manual de um codigo', (tester) async {
    String? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ManualEntryForm(
            onSubmit: (value) => submitted = value,
            selectedWarehouseCode: null,
            onWarehouseChanged: (_) {},
            warehouseOptions: const [
              DropdownMenuItem<String?>(
                value: null,
                child: Text('Sem armazem definido'),
              ),
            ],
            companyPreview: null,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '7891234567890');
    await tester.tap(find.text('Adicionar'));
    await tester.pump();

    expect(submitted, '7891234567890');
  });
}
