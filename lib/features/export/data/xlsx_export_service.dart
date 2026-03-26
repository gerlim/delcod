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
      TextCellValue('Codigo'),
    ]);

    for (final code in payload.codes) {
      sheet.appendRow([
        TextCellValue(code),
      ]);
    }

    final bytes = workbook.encode() ?? <int>[];
    return Uint8List.fromList(bytes);
  }
}
