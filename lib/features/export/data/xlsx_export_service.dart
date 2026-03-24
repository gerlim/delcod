import 'dart:typed_data';

import 'package:barcode_app/features/export/domain/export_collection_payload.dart';
import 'package:excel/excel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final xlsxExportServiceProvider = Provider<XlsxExportService>((ref) {
  return const XlsxExportService();
});

class XlsxExportService {
  const XlsxExportService();

  Uint8List buildFile(ExportCollectionPayload payload) {
    final workbook = Excel.createExcel();
    final sheet = workbook['Leituras'];

    sheet.appendRow([
      TextCellValue('Código'),
      TextCellValue('Tipo'),
      TextCellValue('Origem'),
      TextCellValue('Operador'),
      TextCellValue('Data/Hora'),
    ]);

    for (final row in payload.rows) {
      sheet.appendRow([
        TextCellValue(row.code),
        TextCellValue(row.type),
        TextCellValue(row.source),
        TextCellValue(row.operatorName),
        TextCellValue(_formatDateTime(row.recordedAt)),
      ]);
    }

    final bytes = workbook.encode() ?? <int>[];
    return Uint8List.fromList(bytes);
  }

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
