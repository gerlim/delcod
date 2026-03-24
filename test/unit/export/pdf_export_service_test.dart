import 'package:barcode_app/features/export/data/pdf_export_service.dart';
import 'package:barcode_app/features/export/domain/export_collection_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gera um arquivo pdf válido para a coleta', () async {
    final service = PdfExportService();
    final bytes = await service.buildFile(
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

    expect(bytes.length, greaterThan(100));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
