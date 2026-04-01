import 'package:barcode_app/features/import/data/reading_import_service.dart';
import 'package:barcode_app/features/import/presentation/import_readings_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('preseleciona as colunas de lote e armazem quando o cabecalho e reconhecido',
      (tester) async {
    const table = ImportedTable(
      rows: [
        ['Status', 'Armazém', 'Lote Bobina'],
        ['LI', '05', '001126023205936309'],
      ],
      columnCount: 3,
      suggestedHasHeader: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ImportReadingsDialog(
            filename: 'saldos.xlsx',
            table: table,
            existingCodes: {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lote Bobina'), findsWidgets);
    expect(find.text('Armazém'), findsWidgets);
  });
}
