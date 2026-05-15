import 'dart:convert';
import 'dart:typed_data';

import 'package:barcode_app/features/inventory/domain/inventory_import_models.dart';
import 'package:excel/excel.dart';

class InventoryImportService {
  const InventoryImportService();

  InventoryImportValidation parseXlsx({
    required String filename,
    required Uint8List bytes,
  }) {
    final normalizedFilename = filename.toLowerCase();
    if (!normalizedFilename.endsWith('.xlsx') &&
        !normalizedFilename.endsWith('.xls')) {
      return InventoryImportValidation(
        filename: filename,
        items: const <InventoryItemDraft>[],
        errors: const [
          InventoryImportError(
            message: 'Apenas arquivos .xlsx ou .xls sao aceitos.',
          ),
        ],
      );
    }

    final rows = _readRows(bytes);
    if (rows == null) {
      return InventoryImportValidation(
        filename: filename,
        items: const <InventoryItemDraft>[],
        errors: const [
          InventoryImportError(
            message:
                'Nao foi possivel ler a planilha. Se for um .xls antigo, abra no Excel e salve como .xlsx.',
          ),
        ],
      );
    }

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
    final warnings = <InventoryImportError>[];
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
            message: 'Empresa obrigatoria quando armazem nao foi informado.',
            rowNumber: rowNumber,
          ),
        );
        continue;
      }

      final duplicateFirstRow = seenBarcodes[barcode];
      if (duplicateFirstRow != null) {
        warnings.add(
          InventoryImportError(
            message:
                'Codigo de barras duplicado: $barcode nas linhas $duplicateFirstRow e $rowNumber. Linha mantida na planilha, mas nao importada como nova bobina.',
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
      warnings: warnings,
    );
  }

  List<List<String>>? _readRows(Uint8List bytes) {
    final workbookRows = _readXlsxRows(bytes);
    if (workbookRows != null) {
      return workbookRows;
    }
    return _readTextSpreadsheetRows(bytes);
  }

  List<List<String>>? _readXlsxRows(Uint8List bytes) {
    try {
      final workbook = Excel.decodeBytes(bytes);
      final sheet = _firstUsableSheet(workbook);
      if (sheet == null) {
        return null;
      }
      return sheet.rows
          .map(
            (row) => row
                .map((cell) => _cellValueToText(cell?.value).trim())
                .toList(growable: false),
          )
          .where((row) => row.any((cell) => cell.isNotEmpty))
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  List<List<String>>? _readTextSpreadsheetRows(Uint8List bytes) {
    for (final text in _decodeTextCandidates(bytes)) {
      final htmlRows = _parseHtmlTableRows(text);
      if (_hasUsableRows(htmlRows)) {
        return htmlRows;
      }

      final separatedRows = _parseSeparatedRows(text);
      if (_hasUsableRows(separatedRows)) {
        return separatedRows;
      }
    }
    return null;
  }

  Iterable<String> _decodeTextCandidates(Uint8List bytes) sync* {
    yield utf8.decode(bytes, allowMalformed: true);
    yield latin1.decode(bytes, allowInvalid: true);
  }

  List<List<String>> _parseHtmlTableRows(String text) {
    final rows = <List<String>>[];
    final rowPattern = RegExp(
      r'<tr\b[^>]*>(.*?)</tr>',
      caseSensitive: false,
      dotAll: true,
    );
    final cellPattern = RegExp(
      r'<t[dh]\b[^>]*>(.*?)</t[dh]>',
      caseSensitive: false,
      dotAll: true,
    );

    for (final rowMatch in rowPattern.allMatches(text)) {
      final rowHtml = rowMatch.group(1) ?? '';
      final row = cellPattern
          .allMatches(rowHtml)
          .map((match) => _htmlCellToText(match.group(1) ?? ''))
          .toList(growable: false);
      if (row.any((cell) => cell.isNotEmpty)) {
        rows.add(row);
      }
    }
    return rows;
  }

  List<List<String>> _parseSeparatedRows(String text) {
    final lines = const LineSplitter()
        .convert(text)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) {
      return const <List<String>>[];
    }

    final delimiter = _detectDelimiter(lines.first);
    return lines
        .map(
            (line) => line.split(delimiter).map((cell) => cell.trim()).toList())
        .where((row) => row.any((cell) => cell.isNotEmpty))
        .toList(growable: false);
  }

  Pattern _detectDelimiter(String headerLine) {
    final tabs = '\t'.allMatches(headerLine).length;
    final semicolons = ';'.allMatches(headerLine).length;
    final commas = ','.allMatches(headerLine).length;
    if (tabs >= semicolons && tabs >= commas && tabs > 0) {
      return '\t';
    }
    if (semicolons >= commas && semicolons > 0) {
      return ';';
    }
    return ',';
  }

  bool _hasUsableRows(List<List<String>> rows) {
    return rows.length >= 2 && rows.first.length > 1;
  }

  String _htmlCellToText(String html) {
    final withoutTags = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ');
    return _decodeHtmlEntities(withoutTags)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _decodeHtmlEntities(String value) {
    return value
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
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
    return _deriveCompanyNameFromWarehouse(warehouse) ?? warehouse.trim();
  }

  String? _deriveCompanyNameFromWarehouse(String warehouse) {
    return switch (warehouse.trim().toUpperCase()) {
      'GTR DEL' => 'GTR Del',
      'GTR BORA' => 'GTR Bora',
      'GTR ABN' => 'GTR Abn',
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
      final ascii = switch (rune) {
        0x00e1 || 0x00e0 || 0x00e2 || 0x00e3 || 0x00e4 => 'a',
        0x00e9 || 0x00e8 || 0x00ea || 0x00eb => 'e',
        0x00ed || 0x00ec || 0x00ee || 0x00ef => 'i',
        0x00f3 || 0x00f2 || 0x00f4 || 0x00f5 || 0x00f6 => 'o',
        0x00fa || 0x00f9 || 0x00fb || 0x00fc => 'u',
        0x00e7 => 'c',
        _ => null,
      };
      if (ascii != null) {
        buffer.write(ascii);
        continue;
      }
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
    aliases: {'codigo', 'codigo da bobina', 'bobbin code', 'produto', 'item'},
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
      'lote',
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
      'qtd_atual',
      'qtd atual',
      'quantidade atual',
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
