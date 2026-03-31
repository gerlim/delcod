import 'dart:typed_data';

import 'package:barcode_app/features/export/domain/export_readings_payload.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

final pdfExportServiceProvider = Provider<PdfExportService>((ref) {
  return const PdfExportService();
});

class PdfExportService {
  const PdfExportService();

  Future<Uint8List> buildFile(ExportReadingsPayload payload) async {
    final theme = await _loadTheme();
    final document = pw.Document(theme: theme);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text(
            payload.title,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Total de lotes: ${payload.rows.length}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Lote de Bobina',
              'Armazem',
              'Empresa',
              'Status',
            ],
            data: payload.rows
                .map(
                  (row) => [
                    row.lot,
                    row.warehouseCode ?? 'Nao informado',
                    row.companyName ?? 'Pendente',
                    row.isPendingWarehouse
                        ? 'Sem armazem alocado'
                        : 'Completo',
                  ],
                )
                .toList(growable: false),
          ),
        ],
      ),
    );

    return document.save();
  }

  Future<pw.ThemeData?> _loadTheme() async {
    try {
      final baseFont = await PdfGoogleFonts.openSansRegular();
      final boldFont = await PdfGoogleFonts.openSansBold();
      return pw.ThemeData.withFont(
        base: baseFont,
        bold: boldFont,
      );
    } catch (_) {
      return null;
    }
  }
}
