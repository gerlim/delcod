import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final readingImportServiceProvider = Provider<ReadingImportService>((ref) {
  return const ReadingImportService();
});

class ReadingImportService {
  const ReadingImportService();

  ImportedTable parseFile({
    required String filename,
    required Uint8List bytes,
  }) {
    final normalizedName = filename.toLowerCase();
    final rows = normalizedName.endsWith('.csv')
        ? _parseCsv(bytes)
        : normalizedName.endsWith('.xlsx')
            ? _parseXlsx(bytes)
            : throw const FormatException('Tipo de arquivo nao suportado.');

    final sanitizedRows = _sanitizeRows(rows);
    if (sanitizedRows.isEmpty) {
      throw const FormatException('Arquivo vazio ou sem linhas utilizaveis.');
    }

    final columnCount = sanitizedRows.fold<int>(
      0,
      (max, row) => row.length > max ? row.length : max,
    );

    if (columnCount == 0) {
      throw const FormatException('Nenhuma coluna utilizavel foi encontrada.');
    }

    final normalized = sanitizedRows
        .map((row) => List<String>.generate(
              columnCount,
              (index) => index < row.length ? row[index] : '',
              growable: false,
            ))
        .toList(growable: false);

    return ImportedTable(
      rows: normalized,
      columnCount: columnCount,
      suggestedHasHeader: _suggestHasHeader(normalized),
    );
  }

  ReadingImportAnalysis buildAnalysis({
    required ImportedTable table,
    required int selectedColumnIndex,
    required bool hasHeader,
    required Set<String> existingCodes,
    Map<String, int> metadataColumns = const {},
  }) {
    final entries = table.extractEntries(
      selectedColumnIndex: selectedColumnIndex,
      hasHeader: hasHeader,
      metadataColumns: metadataColumns,
    );

    final knownCodes = existingCodes.map(_normalizeCode).toSet();
    final seenInFile = <String>{};
    final newEntries = <ImportedReadingEntry>[];
    final duplicateEntries = <ImportedReadingEntry>[];

    for (final entry in entries) {
      final normalized = _normalizeCode(entry.code);
      if (normalized.isEmpty) {
        continue;
      }

      final duplicate =
          knownCodes.contains(normalized) || seenInFile.contains(normalized);
      if (duplicate) {
        duplicateEntries.add(entry.copyWith(code: normalized));
        continue;
      }

      seenInFile.add(normalized);
      newEntries.add(entry.copyWith(code: normalized));
    }

    return ReadingImportAnalysis(
      columnLabel:
          table.columnLabelAt(selectedColumnIndex, hasHeader: hasHeader),
      entries: entries,
      newEntries: newEntries,
      duplicateEntries: duplicateEntries,
    );
  }

  List<List<String>> _parseCsv(Uint8List bytes) {
    final content = _decodeText(bytes);
    final delimiter = _detectDelimiter(content);
    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(
      content.replaceAll('\r\n', '\n').replaceAll('\r', '\n'),
      fieldDelimiter: delimiter,
    );

    return rows
        .map(
          (row) => row
              .map((cell) => cell?.toString().trim() ?? '')
              .toList(growable: false),
        )
        .toList(growable: false);
  }

  List<List<String>> _parseXlsx(Uint8List bytes) {
    final workbook = Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) {
      throw const FormatException('Planilha sem abas utilizaveis.');
    }

    for (final sheet in workbook.tables.values) {
      final parsedRows = sheet.rows
          .map(
            (row) => row
                .map((cell) => _cellValueToText(cell?.value))
                .toList(growable: false),
          )
          .toList(growable: false);

      if (parsedRows.any((row) => row.any((cell) => cell.trim().isNotEmpty))) {
        return parsedRows;
      }
    }

    throw const FormatException('Planilha sem abas utilizaveis.');
  }

  List<List<String>> _sanitizeRows(List<List<String>> rows) {
    return rows
        .where((row) => row.any((cell) => cell.trim().isNotEmpty))
        .toList(growable: false);
  }

  bool _suggestHasHeader(List<List<String>> rows) {
    if (rows.length < 2) {
      return false;
    }

    final firstRow = rows.first;
    final secondRow = rows[1];
    final firstScore = _headerLikeScore(firstRow);
    final secondScore = _headerLikeScore(secondRow);
    return firstScore > secondScore;
  }

  int _headerLikeScore(List<String> row) {
    var score = 0;
    for (final cell in row) {
      final trimmed = cell.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      if (RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(trimmed)) {
        score += 2;
      }
      if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
        score += 1;
      }
    }
    return score;
  }

  String _decodeText(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes);
    }
  }

  String _detectDelimiter(String content) {
    final firstLine = content
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .firstWhere(
          (line) => line.trim().isNotEmpty,
          orElse: () => '',
        );

    final semicolonCount = ';'.allMatches(firstLine).length;
    final commaCount = ','.allMatches(firstLine).length;
    return semicolonCount > commaCount ? ';' : ',';
  }

  String _cellValueToText(CellValue? value) {
    if (value == null) {
      return '';
    }

    return switch (value) {
      TextCellValue() => value.value.toString().trim(),
      IntCellValue() => value.value.toString(),
      DoubleCellValue() => value.value.toString(),
      BoolCellValue() => value.value ? 'true' : 'false',
      FormulaCellValue() => value.formula.trim(),
      DateCellValue() => value.asDateTimeLocal().toIso8601String(),
      TimeCellValue() => value.asDuration().toString(),
      DateTimeCellValue() => value.asDateTimeLocal().toIso8601String(),
    };
  }
}

class ImportedTable {
  const ImportedTable({
    required this.rows,
    required this.columnCount,
    required this.suggestedHasHeader,
  });

  final List<List<String>> rows;
  final int columnCount;
  final bool suggestedHasHeader;

  int? get suggestedLotColumnIndex => _findSuggestedColumnIndex(
        aliases: const [
          'lote bobina',
          'lote de bobina',
          'lotebobina',
          'bobbin lot',
        ],
      );

  int? get suggestedWarehouseColumnIndex => _findSuggestedColumnIndex(
        aliases: const [
          'armazem',
          'armazém',
          'warehouse',
        ],
      );

  List<List<String>> previewRows({
    required bool hasHeader,
    int limit = 5,
  }) {
    final startIndex = hasHeader ? 1 : 0;
    if (startIndex >= rows.length) {
      return const <List<String>>[];
    }

    final endIndex = (startIndex + limit) > rows.length
        ? rows.length
        : startIndex + limit;
    return rows.sublist(startIndex, endIndex);
  }

  String columnLabelAt(
    int columnIndex, {
    required bool hasHeader,
  }) {
    if (hasHeader &&
        rows.isNotEmpty &&
        columnIndex < rows.first.length &&
        rows.first[columnIndex].trim().isNotEmpty) {
      return rows.first[columnIndex].trim();
    }

    return 'Coluna ${excelColumnLabel(columnIndex)}';
  }

  int? _findSuggestedColumnIndex({
    required List<String> aliases,
  }) {
    if (!suggestedHasHeader || rows.isEmpty) {
      return null;
    }

    final header = rows.first;
    for (var index = 0; index < header.length; index++) {
      final normalizedHeader = _normalizeHeaderLabel(header[index]);
      if (normalizedHeader.isEmpty) {
        continue;
      }
      if (aliases.any((alias) => _normalizeHeaderLabel(alias) == normalizedHeader)) {
        return index;
      }
    }

    return null;
  }

  List<String> extractCodes({
    required int selectedColumnIndex,
    required bool hasHeader,
  }) {
    return extractEntries(
      selectedColumnIndex: selectedColumnIndex,
      hasHeader: hasHeader,
    ).map((entry) => entry.code).toList(growable: false);
  }

  List<ImportedReadingEntry> extractEntries({
    required int selectedColumnIndex,
    required bool hasHeader,
    Map<String, int> metadataColumns = const {},
  }) {
    final startIndex = hasHeader ? 1 : 0;
    if (selectedColumnIndex < 0 || selectedColumnIndex >= columnCount) {
      return const <ImportedReadingEntry>[];
    }

    final extracted = <ImportedReadingEntry>[];
    for (var rowIndex = startIndex; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      final value =
          selectedColumnIndex < row.length ? row[selectedColumnIndex] : '';
      final normalized = _normalizeCode(value);
      if (normalized.isNotEmpty) {
        extracted.add(
          ImportedReadingEntry(
            code: normalized,
            metadata: _extractMetadata(
              row: row,
              metadataColumns: metadataColumns,
            ),
          ),
        );
      }
    }
    return extracted;
  }

  Map<String, String> _extractMetadata({
    required List<String> row,
    required Map<String, int> metadataColumns,
  }) {
    final metadata = <String, String>{};
    for (final entry in metadataColumns.entries) {
      final index = entry.value;
      if (index < 0 || index >= row.length) {
        continue;
      }
      final value = row[index].trim();
      if (value.isEmpty) {
        continue;
      }
      metadata[entry.key] = value;
    }
    return metadata;
  }

  static String excelColumnLabel(int index) {
    var current = index;
    var label = '';

    do {
      final charCode = 65 + (current % 26);
      label = String.fromCharCode(charCode) + label;
      current = (current ~/ 26) - 1;
    } while (current >= 0);

    return label;
  }
}

class ReadingImportAnalysis {
  const ReadingImportAnalysis({
    required this.columnLabel,
    required this.entries,
    required this.newEntries,
    required this.duplicateEntries,
  });

  final String columnLabel;
  final List<ImportedReadingEntry> entries;
  final List<ImportedReadingEntry> newEntries;
  final List<ImportedReadingEntry> duplicateEntries;

  int get totalCodes => entries.length;
  List<String> get extractedCodes =>
      entries.map((entry) => entry.code).toList(growable: false);
  List<String> get newCodes =>
      newEntries.map((entry) => entry.code).toList(growable: false);
  List<String> get duplicateCodes =>
      duplicateEntries.map((entry) => entry.code).toList(growable: false);
}

String _normalizeCode(String value) {
  return value.replaceAll(RegExp(r'\s+'), '').trim();
}

String _normalizeHeaderLabel(String value) {
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

class ImportedReadingEntry {
  const ImportedReadingEntry({
    required this.code,
    this.metadata = const {},
  });

  final String code;
  final Map<String, String> metadata;

  ImportedReadingEntry copyWith({
    String? code,
    Map<String, String>? metadata,
  }) {
    return ImportedReadingEntry(
      code: code ?? this.code,
      metadata: metadata ?? this.metadata,
    );
  }
}
