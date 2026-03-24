import 'package:barcode_app/features/export/data/xlsx_export_service.dart';
import 'package:barcode_app/features/export/domain/export_collection_payload.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gera uma planilha com cabeçalhos e leituras', () {
    final service = XlsxExportService();
    final bytes = service.buildFile(
      ExportCollectionPayload(
        companyName: 'Empresa A',
        collectionTitle: 'Coleta Expedição 01',
        rows: [
          ExportReadingRow(
            code: '7891234567890',
            type: 'EAN-13',
            source: 'camera',
            operatorName: 'Operador 01',
            recordedAt: DateTime(2026, 3, 23, 10, 30),
          ),
        ],
      ),
    );

    final workbook = Excel.decodeBytes(bytes);
    final sheet = workbook.tables['Leituras'];

    expect(sheet, isNotNull);
    expect(sheet!.rows.first.map((cell) => cell?.value?.toString()).toList(), [
      'Código',
      'Tipo',
      'Origem',
      'Operador',
      'Data/Hora',
    ]);
    expect(sheet.rows[1][0]?.value.toString(), '7891234567890');
  });
}
