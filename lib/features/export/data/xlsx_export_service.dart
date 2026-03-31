import 'dart:typed_data';

import 'package:barcode_app/features/export/domain/export_readings_payload.dart';
import 'package:excel/excel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final xlsxExportServiceProvider = Provider<XlsxExportService>((ref) {
  return const XlsxExportService();
});

class XlsxExportService {
  const XlsxExportService();

  Uint8List buildFile(ExportReadingsPayload payload) {
    final workbook = Excel.createExcel();
    final sheet = workbook['Leituras'];

    sheet.appendRow([
      TextCellValue('Lote de Bobina'),
      TextCellValue('Armazem'),
      TextCellValue('Empresa'),
      TextCellValue('Status'),
    ]);

    for (final row in payload.rows) {
      sheet.appendRow([
        TextCellValue(row.lot),
        TextCellValue(row.warehouseCode ?? 'Nao informado'),
        TextCellValue(row.companyName ?? 'Pendente'),
        TextCellValue(
          row.isPendingWarehouse ? 'Sem armazem alocado' : 'Completo',
        ),
      ]);
    }

    final bytes = workbook.encode() ?? <int>[];
    return Uint8List.fromList(bytes);
  }
}
