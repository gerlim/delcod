import 'package:barcode_app/features/export/data/xlsx_export_service.dart';
import 'package:barcode_app/features/export/domain/export_readings_payload.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gera uma planilha simples com os codigos selecionados', () {
    final service = XlsxExportService();
    final bytes = service.buildFile(
      const ExportReadingsPayload(
        title: 'Lista global',
        codes: [
          '7891234567890',
          '2223334445556',
        ],
      ),
    );

    final workbook = Excel.decodeBytes(bytes);
    final sheet = workbook.tables['Leituras'];

    expect(sheet, isNotNull);
    expect(
      sheet!.rows.first.map((cell) => cell?.value?.toString()).toList(),
      ['Codigo'],
    );
    expect(sheet.rows[1][0]?.value.toString(), '7891234567890');
    expect(sheet.rows[2][0]?.value.toString(), '2223334445556');
  });
}
