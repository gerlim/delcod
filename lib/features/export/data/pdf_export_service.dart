import 'dart:typed_data';

import 'package:barcode_app/features/export/domain/export_collection_payload.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

final pdfExportServiceProvider = Provider<PdfExportService>((ref) {
  return const PdfExportService();
});

class PdfExportService {
  const PdfExportService();

  Future<Uint8List> buildFile(ExportCollectionPayload payload) async {
    final theme = await _loadTheme();
    final document = pw.Document(theme: theme);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text(
            payload.companyName,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Coleta: ${payload.collectionTitle}'),
          pw.Text('Total de leituras: ${payload.rows.length}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Código',
              'Tipo',
              'Origem',
              'Operador',
              'Data/Hora',
            ],
            data: payload.rows
                .map(
                  (row) => [
                    row.code,
                    row.type,
                    row.source,
                    row.operatorName,
                    _formatDateTime(row.recordedAt),
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

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
