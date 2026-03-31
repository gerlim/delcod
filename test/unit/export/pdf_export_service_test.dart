import 'package:barcode_app/features/export/data/pdf_export_service.dart';
import 'package:barcode_app/features/export/domain/export_readings_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gera um arquivo pdf valido para os codigos selecionados', () async {
    const service = PdfExportService();
    final bytes = await service.buildFile(
      const ExportReadingsPayload(
        title: 'Lista global',
        rows: [
          ExportReadingRow(
            lot: '7891234567890',
            warehouseCode: '05',
            companyName: 'Bora Embalagens',
            isPendingWarehouse: false,
          ),
        ],
      ),
    );

    expect(bytes.length, greaterThan(100));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
