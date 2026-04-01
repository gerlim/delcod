import 'dart:convert';
import 'dart:typed_data';

import 'package:barcode_app/features/import/data/reading_import_service.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReadingImportService', () {
    test('le CSV com cabecalho, detecta colunas e resume duplicados', () {
      const service = ReadingImportService();
      final bytes = Uint8List.fromList(
        utf8.encode(
          'Codigo;Descricao\n789123;Item A\n456789;Item B\n',
        ),
      );

      final table = service.parseFile(
        filename: 'leituras.csv',
        bytes: bytes,
      );
      final analysis = service.buildAnalysis(
        table: table,
        selectedColumnIndex: 0,
        hasHeader: true,
        existingCodes: {'789123'},
      );

      expect(table.columnCount, 2);
      expect(table.suggestedHasHeader, isTrue);
      expect(table.columnLabelAt(0, hasHeader: true), 'Codigo');
      expect(table.columnLabelAt(1, hasHeader: true), 'Descricao');
      expect(analysis.totalCodes, 2);
      expect(analysis.newCodes, ['456789']);
      expect(analysis.duplicateCodes, ['789123']);
    });

    test('le XLSX sem cabecalho e usa rotulo padrao de coluna', () {
      const service = ReadingImportService();
      final workbook = Excel.createExcel();
      final sheet = workbook['Leituras'];

      sheet.appendRow([
        TextCellValue('111'),
        TextCellValue('Primeira'),
      ]);
      sheet.appendRow([
        TextCellValue('222'),
        TextCellValue('Segunda'),
      ]);

      final bytes = Uint8List.fromList(workbook.encode()!);
      final table = service.parseFile(
        filename: 'leituras.xlsx',
        bytes: bytes,
      );
      final analysis = service.buildAnalysis(
        table: table,
        selectedColumnIndex: 0,
        hasHeader: false,
        existingCodes: const {},
      );

      expect(table.columnCount, 2);
      expect(table.columnLabelAt(0, hasHeader: false), 'Coluna A');
      expect(table.columnLabelAt(1, hasHeader: false), 'Coluna B');
      expect(analysis.totalCodes, 2);
      expect(analysis.newCodes, ['111', '222']);
      expect(analysis.duplicateCodes, isEmpty);
    });

    test('extrai metadados opcionais por coluna sem mudar a regra de duplicidade', () {
      const service = ReadingImportService();
      final bytes = Uint8List.fromList(
        utf8.encode(
          'Codigo;Lote;Peso\n789123;L-10;14,6\n789123;L-11;14,7\n',
        ),
      );

      final table = service.parseFile(
        filename: 'leituras.csv',
        bytes: bytes,
      );
      final analysis = service.buildAnalysis(
        table: table,
        selectedColumnIndex: 0,
        hasHeader: true,
        existingCodes: const {},
        metadataColumns: const {
          'batch': 1,
          'weight': 2,
        },
      );

      expect(analysis.totalCodes, 2);
      expect(analysis.newCodes, ['789123']);
      expect(analysis.duplicateCodes, ['789123']);
      expect(analysis.entries.first.metadata, const {
        'batch': 'L-10',
        'weight': '14,6',
      });
      expect(analysis.duplicateEntries.first.metadata, const {
        'batch': 'L-11',
        'weight': '14,7',
      });
    });

    test('sugere automaticamente as colunas de lote de bobina e armazem pelo cabecalho', () {
      const service = ReadingImportService();
      final bytes = Uint8List.fromList(
        utf8.encode(
          'Status;Armazém;Lote Bobina;Observacao\nLI;05;001126023205936309;Ok\n',
        ),
      );

      final table = service.parseFile(
        filename: 'saldos.csv',
        bytes: bytes,
      );

      expect(table.suggestedHasHeader, isTrue);
      expect(table.suggestedLotColumnIndex, 2);
      expect(table.suggestedWarehouseColumnIndex, 1);
    });

    test('reconhece variacoes sem acento e com espacos extras no cabecalho', () {
      const service = ReadingImportService();
      final bytes = Uint8List.fromList(
        utf8.encode(
          '  armazem ; lote de bobina ; status \nPPI;001125816205936325;LI\n',
        ),
      );

      final table = service.parseFile(
        filename: 'saldos.csv',
        bytes: bytes,
      );

      expect(table.suggestedWarehouseColumnIndex, 0);
      expect(table.suggestedLotColumnIndex, 1);
    });
  });
}
