import 'package:barcode_app/features/export/data/xlsx_export_service.dart';
import 'package:barcode_app/features/export/domain/export_readings_payload.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gera uma planilha simples com os codigos selecionados', () {
    const service = XlsxExportService();
    final bytes = service.buildFile(
      const ExportReadingsPayload(
        title: 'Lista global',
        rows: [
          ExportReadingRow(
            lot: '7891234567890',
            warehouseCode: '05',
            companyName: 'Bora Embalagens',
            isPendingWarehouse: false,
          ),
          ExportReadingRow(
            lot: '2223334445556',
            warehouseCode: null,
            companyName: null,
            isPendingWarehouse: true,
          ),
        ],
      ),
    );

    final workbook = Excel.decodeBytes(bytes);
    final sheet = workbook.tables['Leituras'];

    expect(sheet, isNotNull);
    expect(
      sheet!.rows.first.map((cell) => cell?.value?.toString()).toList(),
      ['Lote de Bobina', 'Armazem', 'Empresa', 'Status'],
    );
    expect(sheet.rows[1][0]?.value.toString(), '7891234567890');
    expect(sheet.rows[1][1]?.value.toString(), '05');
    expect(sheet.rows[1][2]?.value.toString(), 'Bora Embalagens');
    expect(sheet.rows[1][3]?.value.toString(), 'Completo');
    expect(sheet.rows[2][0]?.value.toString(), '2223334445556');
    expect(sheet.rows[2][1]?.value.toString(), 'Nao informado');
    expect(sheet.rows[2][2]?.value.toString(), 'Pendente');
    expect(sheet.rows[2][3]?.value.toString(), 'Sem armazem alocado');
  });
}
