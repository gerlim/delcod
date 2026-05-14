import 'dart:typed_data';

import 'package:barcode_app/features/inventory/application/inventory_export_builder.dart';
import 'package:barcode_app/features/inventory/data/inventory_audit_result_mapper.dart';
import 'package:barcode_app/features/inventory/domain/inventory_audit_result.dart';
import 'package:excel/excel.dart';

export 'package:barcode_app/features/inventory/application/inventory_export_builder.dart'
    show InventoryAuditExport;

class InventoryAuditXlsxExportService {
  const InventoryAuditXlsxExportService();

  Uint8List buildFile(InventoryAuditExport export) {
    final workbook = Excel.createExcel();
    workbook.delete('Sheet1');

    _writeSheet(workbook, 'Corretos', export.correct);
    _writeSheet(workbook, 'Incorretos', export.incorrect);
    _writeSheet(workbook, 'Nao encontrados', export.notFound);
    _writeSheet(workbook, 'Pendentes', export.pending);

    return Uint8List.fromList(workbook.encode()!);
  }

  void _writeSheet(
    Excel workbook,
    String name,
    List<InventoryAuditExportRow> rows,
  ) {
    final sheet = workbook[name];
    sheet.appendRow(
      const [
        'Empresa',
        'Codigo',
        'Descricao',
        'Codigo de barras',
        'Peso',
        'Armazem',
        'Status',
        'Campos divergentes',
        'Observacao',
        'Data da auditoria',
      ].map(TextCellValue.new).toList(growable: false),
    );

    for (final row in rows) {
      final item = row.item;
      final result = row.result;
      sheet.appendRow(
        [
          item?.companyName ?? '',
          item?.bobbinCode ?? '',
          item?.itemDescription ?? '',
          item?.barcode ?? result?.scannedBarcode ?? '',
          item?.weight ?? '',
          item?.warehouse ?? '',
          result?.status.remoteValue ?? 'pending',
          result == null
              ? ''
              : result.discrepancyFields.map((field) => field.label).join(', '),
          result?.note ?? '',
          result?.scannedAt.toIso8601String() ?? '',
        ].map(TextCellValue.new).toList(growable: false),
      );
    }
  }
}
