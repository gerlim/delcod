import 'dart:typed_data';

import 'package:barcode_app/features/inventory/domain/inventory_import_models.dart';
import 'package:excel/excel.dart';

class InventoryImportService {
  const InventoryImportService();

  InventoryImportValidation parseXlsx({
    required String filename,
    required Uint8List bytes,
  }) {
    if (!filename.toLowerCase().endsWith('.xlsx')) {
      return InventoryImportValidation(
        filename: filename,
        items: const <InventoryItemDraft>[],
        errors: const [
          InventoryImportError(message: 'Apenas arquivos .xlsx sao aceitos.'),
        ],
      );
    }

    final workbook = Excel.decodeBytes(bytes);
    final sheet = _firstUsableSheet(workbook);
    if (sheet == null) {
      return InventoryImportValidation(
        filename: filename,
        items: const <InventoryItemDraft>[],
        errors: const [
          InventoryImportError(message: 'Planilha sem linhas utilizaveis.'),
        ],
      );
    }

    final rows = sheet.rows
        .map(
          (row) => row
              .map((cell) => _cellValueToText(cell?.value).trim())
              .toList(growable: false),
        )
        .where((row) => row.any((cell) => cell.isNotEmpty))
        .toList(growable: false);

    if (rows.length < 2) {
      return InventoryImportValidation(
        filename: filename,
        items: const <InventoryItemDraft>[],
        errors: const [
          InventoryImportError(
            message: 'Planilha precisa ter cabecalho e ao menos um item.',
          ),
        ],
      );
    }

    final header = rows.first;
    final columns = _resolveColumns(header);
    final errors = <InventoryImportError>[];
    for (final requiredColumn in InventoryImportColumn.requiredColumns) {
      if (!columns.containsKey(requiredColumn)) {
        errors.add(
          InventoryImportError(
            message: 'Coluna obrigatoria ausente: ${requiredColumn.label}.',
            rowNumber: 1,
          ),
        );
      }
    }

    if (errors.isNotEmpty) {
      return InventoryImportValidation(
        filename: filename,
        items: const <InventoryItemDraft>[],
        errors: errors,
      );
    }

    final items = <InventoryItemDraft>[];
    final seenBarcodes = <String, int>{};
    for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      final rowNumber = rowIndex + 1;
      final barcode = _value(row, columns[InventoryImportColumn.barcode]!);
      final warehouse = _value(row, columns[InventoryImportColumn.warehouse]!);
      final companyName = _resolveCompanyName(row, columns, warehouse);

      if (barcode.isEmpty && companyName.isEmpty) {
        continue;
      }

      if (barcode.isEmpty) {
        errors.add(
          InventoryImportError(
            message: 'Codigo de barras obrigatorio.',
            rowNumber: rowNumber,
          ),
        );
        continue;
      }

      if (companyName.isEmpty) {
        errors.add(
          InventoryImportError(
            message: 'Empresa obrigatoria ou armazem sem mapeamento conhecido.',
            rowNumber: rowNumber,
          ),
        );
        continue;
      }

      final duplicateFirstRow = seenBarcodes[barcode];
      if (duplicateFirstRow != null) {
        errors.add(
          InventoryImportError(
            message:
                'Codigo de barras duplicado: $barcode nas linhas $duplicateFirstRow e $rowNumber.',
            rowNumber: rowNumber,
          ),
        );
        continue;
      }
      seenBarcodes[barcode] = rowNumber;

      items.add(
        InventoryItemDraft(
          companyName: companyName,
          bobbinCode: _value(row, columns[InventoryImportColumn.bobbinCode]!),
          itemDescription:
              _value(row, columns[InventoryImportColumn.description]!),
          barcode: barcode,
          weight: _value(row, columns[InventoryImportColumn.weight]!),
          warehouse: warehouse,
          rowNumber: rowNumber,
          rawPayload: _rawPayload(header, row),
        ),
      );
    }

    return InventoryImportValidation(
      filename: filename,
      items: items,
      errors: errors,
    );
  }

  Sheet? _firstUsableSheet(Excel workbook) {
    for (final sheet in workbook.tables.values) {
      if (sheet.rows.any(
        (row) => row.any((cell) => _cellValueToText(cell?.value).isNotEmpty),
      )) {
        return sheet;
      }
    }
    return null;
  }

  Map<InventoryImportColumn, int> _resolveColumns(List<String> header) {
    final columns = <InventoryImportColumn, int>{};
    for (var index = 0; index < header.length; index++) {
      final normalized = _normalizeHeader(header[index]);
      for (final column in InventoryImportColumn.values) {
        if (column.aliases.contains(normalized)) {
          columns.putIfAbsent(column, () => index);
        }
      }
    }
    return columns;
  }

  String _value(List<String> row, int index) {
    if (index < 0 || index >= row.length) {
      return '';
    }
    return row[index].trim();
  }

  String _resolveCompanyName(
    List<String> row,
    Map<InventoryImportColumn, int> columns,
    String warehouse,
  ) {
    final companyColumn = columns[InventoryImportColumn.company];
    if (companyColumn != null) {
      final companyName = _value(row, companyColumn);
      if (companyName.isNotEmpty) {
        return companyName;
      }
    }
    return _deriveCompanyNameFromWarehouse(warehouse) ?? '';
  }

  String? _deriveCompanyNameFromWarehouse(String warehouse) {
    return switch (warehouse.trim().toUpperCase()) {
      '05' || 'PPI' => 'Bora Embalagens',
      '04' || 'GLR' => 'ABN Embalagens',
      _ => null,
    };
  }

  Map<String, String> _rawPayload(List<String> header, List<String> row) {
    final payload = <String, String>{};
    for (var index = 0; index < header.length; index++) {
      final key = header[index].trim();
      if (key.isEmpty) {
        continue;
      }
      payload[key] = index < row.length ? row[index].trim() : '';
    }
    return payload;
  }

  String _cellValueToText(CellValue? value) {
    if (value == null) {
      return '';
    }
    return switch (value) {
      TextCellValue() => value.value.toString(),
      IntCellValue() => value.value.toString(),
      DoubleCellValue() => value.value.toString(),
      BoolCellValue() => value.value ? 'true' : 'false',
      FormulaCellValue() => value.formula,
      DateCellValue() => value.asDateTimeLocal().toIso8601String(),
      TimeCellValue() => value.asDuration().toString(),
      DateTimeCellValue() => value.asDateTimeLocal().toIso8601String(),
    };
  }

  String _normalizeHeader(String value) {
    final lowercase = value.trim().toLowerCase();
    const accentMap = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };

    final buffer = StringBuffer();
    for (final rune in lowercase.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(accentMap[char] ?? char);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

enum InventoryImportColumn {
  company(
    label: 'empresa',
    aliases: {'empresa', 'company', 'companhia'},
  ),
  bobbinCode(
    label: 'codigo',
    aliases: {'codigo', 'codigo da bobina', 'bobbin code', 'produto'},
  ),
  description(
    label: 'descricao',
    aliases: {
      'descricao',
      'descricao do item',
      'item description',
      'produto descricao'
    },
  ),
  barcode(
    label: 'codigo de barras',
    aliases: {
      'codigo de barras',
      'barcode',
      'ean',
      'lote bobina',
      'lote de bobina',
    },
  ),
  weight(
    label: 'peso',
    aliases: {
      'peso',
      'weight',
      'saldo bobina',
      'saldo da bobina',
    },
  ),
  warehouse(
    label: 'armazem',
    aliases: {'armazem', 'warehouse'},
  );

  const InventoryImportColumn({
    required this.label,
    required this.aliases,
  });

  final String label;
  final Set<String> aliases;

  static const requiredColumns = <InventoryImportColumn>{
    bobbinCode,
    description,
    barcode,
    weight,
    warehouse,
  };
}
