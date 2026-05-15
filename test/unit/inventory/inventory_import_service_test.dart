import 'dart:convert';
import 'dart:typed_data';

import 'package:barcode_app/features/inventory/data/inventory_import_service.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('imports xlsx inventory with mixed companies', () {
    const service = InventoryImportService();
    final result = service.parseXlsx(
      filename: 'inventario.xlsx',
      bytes: _buildWorkbook([
        [
          'Empresa',
          'Codigo',
          'Descricao',
          'Codigo de Barras',
          'Peso',
          'Armazem'
        ],
        [
          'Bora Embalagens',
          'BOB-001',
          'Papel kraft',
          '789001',
          '482,5',
          '05',
        ],
        [
          'ABN Embalagens',
          'BOB-002',
          'Papel branco',
          '789002',
          '510',
          'GLR',
        ],
      ]),
    );

    expect(result.isValid, isTrue);
    expect(result.items, hasLength(2));
    expect(result.items.first.companyName, 'Bora Embalagens');
    expect(result.items.last.companyName, 'ABN Embalagens');
    expect(result.items.first.barcode, '789001');
    expect(result.items.first.weight, '482,5');
  });

  test('skips duplicate barcodes in the same import', () {
    const service = InventoryImportService();
    final result = service.parseXlsx(
      filename: 'inventario.xlsx',
      bytes: _buildWorkbook([
        [
          'Empresa',
          'Codigo',
          'Descricao',
          'Codigo de Barras',
          'Peso',
          'Armazem'
        ],
        ['Bora Embalagens', 'BOB-001', 'Papel kraft', '789001', '482,5', '05'],
        ['ABN Embalagens', 'BOB-002', 'Papel branco', '789001', '510', 'GLR'],
      ]),
    );

    expect(result.isValid, isTrue);
    expect(result.items, hasLength(1));
    expect(result.items.single.companyName, 'Bora Embalagens');
    expect(result.warnings.single.message, contains('789001'));
  });

  test('imports real Protheus saldo layout deriving company by warehouse', () {
    const service = InventoryImportService();
    final result = service.parseXlsx(
      filename: 'saldos_exportados.xlsx',
      bytes: _buildWorkbook([
        [
          'Produto',
          'Descrição',
          'Un',
          'Qtde Original',
          'Saldo Bobina',
          'Saldo Proc.',
          'Armazém',
          'Lote Bobina',
          'Lote Protheus',
          'Status',
        ],
        [
          '2059002',
          'CARTAO NILS 275G X 350MM P25CM',
          'KG',
          '378.3',
          '378.3',
          '0.0',
          '05',
          'CORTE2701260117902',
          'ETH0000020',
          'LI',
        ],
        [
          '2059003',
          'CARTAO TESTE',
          'KG',
          '200',
          '199.5',
          '0.0',
          'GLR',
          'RN010825B1205900301',
          'PPI5513022',
          'LI',
        ],
      ]),
    );

    expect(result.isValid, isTrue);
    expect(result.items, hasLength(2));

    final boraItem = result.items.first;
    expect(boraItem.companyName, 'Bora Embalagens');
    expect(boraItem.bobbinCode, '2059002');
    expect(boraItem.itemDescription, 'CARTAO NILS 275G X 350MM P25CM');
    expect(boraItem.weight, '378.3');
    expect(boraItem.warehouse, '05');
    expect(boraItem.barcode, 'CORTE2701260117902');

    final abnItem = result.items.last;
    expect(abnItem.companyName, 'ABN Embalagens');
    expect(abnItem.bobbinCode, '2059003');
    expect(abnItem.weight, '199.5');
    expect(abnItem.warehouse, 'GLR');
    expect(abnItem.barcode, 'RN010825B1205900301');
  });

  test('accepts xlsx content when file extension is xls', () {
    const service = InventoryImportService();
    final result = service.parseXlsx(
      filename: 'inventario.xls',
      bytes: _buildWorkbook([
        [
          'Empresa',
          'Codigo',
          'Descricao',
          'Codigo de Barras',
          'Peso',
          'Armazem'
        ],
        ['Bora Embalagens', 'BOB-001', 'Papel kraft', '789001', '482,5', '05'],
      ]),
    );

    expect(result.isValid, isTrue);
    expect(result.items.single.barcode, '789001');
  });

  test('imports html table exported with xls extension', () {
    const service = InventoryImportService();
    final result = service.parseXlsx(
      filename: 'saldos_exportados.xls',
      bytes: Uint8List.fromList(
        latin1.encode('''
<html>
<body>
<table>
<tr>
  <td>Produto</td>
  <td>Descricao</td>
  <td>Saldo Bobina</td>
  <td>Armazem</td>
  <td>Lote Bobina</td>
</tr>
<tr>
  <td>2059002</td>
  <td>CARTAO NILS 275G X 350MM P25CM</td>
  <td>378.3</td>
  <td>05</td>
  <td>CORTE2701260117902</td>
</tr>
</table>
</body>
</html>
'''),
      ),
    );

    expect(result.isValid, isTrue);
    expect(result.items.single.companyName, 'Bora Embalagens');
    expect(result.items.single.bobbinCode, '2059002');
    expect(result.items.single.barcode, 'CORTE2701260117902');
  });

  test('imports GInventario layout using item, qtd_atual and lote headers', () {
    const service = InventoryImportService();
    final result = service.parseXlsx(
      filename: 'GInventario.xlsx',
      bytes: _buildWorkbook([
        [
          'ITEM',
          'DESCRICAO',
          'UM',
          'qtd_original',
          'qtd_atual',
          'Saldo Proc.',
          'Armazem',
          'LOTE',
        ],
        [
          '2007069',
          'MIOLO 130/140G X 870MM - PESADO',
          'kg',
          '803.0',
          '352.0',
          '',
          'GTR DEL',
          'R0001760010001200706901',
        ],
      ]),
    );

    expect(result.isValid, isTrue);
    expect(result.items.single.companyName, 'GTR Del');
    expect(result.items.single.bobbinCode, '2007069');
    expect(
        result.items.single.itemDescription, 'MIOLO 130/140G X 870MM - PESADO');
    expect(result.items.single.weight, '352.0');
    expect(result.items.single.warehouse, 'GTR DEL');
    expect(result.items.single.barcode, 'R0001760010001200706901');
  });

  test('maps GTR warehouses to explicit company names', () {
    const service = InventoryImportService();
    final result = service.parseXlsx(
      filename: 'GInventario.xlsx',
      bytes: _buildWorkbook([
        ['ITEM', 'DESCRICAO', 'qtd_atual', 'Armazem', 'LOTE'],
        [
          '2059324',
          'CARTAO TESTE',
          '120.0',
          'GTR ABN',
          '28042600201205932411',
        ],
        [
          '2059325',
          'CARTAO TESTE BORA',
          '80.0',
          'GTR BORA',
          '28042600301205932537',
        ],
      ]),
    );

    expect(result.isValid, isTrue);
    expect(result.items.first.companyName, 'GTR Abn');
    expect(result.items.first.warehouse, 'GTR ABN');
    expect(result.items.last.companyName, 'GTR Bora');
    expect(result.items.last.warehouse, 'GTR BORA');
  });
}

Uint8List _buildWorkbook(List<List<String>> rows) {
  final excel = Excel.createExcel();
  final sheet = excel['Inventario'];
  for (final row in rows) {
    sheet.appendRow(
      row.map((value) => TextCellValue(value)).toList(growable: false),
    );
  }
  final bytes = excel.encode();
  if (bytes == null) {
    throw StateError('Failed to encode test workbook.');
  }
  return Uint8List.fromList(bytes);
}
