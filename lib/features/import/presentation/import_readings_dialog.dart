import 'package:barcode_app/app/theme/app_colors.dart';
import 'package:barcode_app/features/import/data/reading_import_service.dart';
import 'package:flutter/material.dart';

enum ImportDialogDecision {
  onlyNew,
  all,
}

class ImportDialogResult {
  const ImportDialogResult({
    required this.decision,
    required this.analysis,
  });

  final ImportDialogDecision decision;
  final ReadingImportAnalysis analysis;
}

class ImportReadingsDialog extends StatefulWidget {
  const ImportReadingsDialog({
    super.key,
    required this.filename,
    required this.table,
    required this.existingCodes,
  });

  final String filename;
  final ImportedTable table;
  final Set<String> existingCodes;

  @override
  State<ImportReadingsDialog> createState() => _ImportReadingsDialogState();
}

class _ImportReadingsDialogState extends State<ImportReadingsDialog> {
  static const _service = ReadingImportService();

  late bool _hasHeader = widget.table.suggestedHasHeader;
  int _selectedColumnIndex = 0;

  @override
  Widget build(BuildContext context) {
    final analysis = _service.buildAnalysis(
      table: widget.table,
      selectedColumnIndex: _selectedColumnIndex,
      hasHeader: _hasHeader,
      existingCodes: widget.existingCodes,
    );
    final previewRows = widget.table.previewRows(hasHeader: _hasHeader);
    final canImport = analysis.totalCodes > 0;

    return AlertDialog(
      title: const Text('Importar arquivo'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.filename,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Confirme o cabecalho, escolha a coluna dos codigos e revise o lote antes de importar.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.steel,
                    ),
              ),
              const SizedBox(height: 20),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('A primeira linha e cabecalho'),
                value: _hasHeader,
                onChanged: (value) {
                  setState(() {
                    _hasHeader = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedColumnIndex,
                decoration: const InputDecoration(
                  labelText: 'Coluna com os codigos',
                ),
                items: List<DropdownMenuItem<int>>.generate(
                  widget.table.columnCount,
                  (index) => DropdownMenuItem<int>(
                    value: index,
                    child: Text(
                      widget.table.columnLabelAt(
                        index,
                        hasHeader: _hasHeader,
                      ),
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedColumnIndex = value;
                  });
                },
              ),
              const SizedBox(height: 18),
              Text(
                'Previa',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              _ImportPreviewTable(
                rows: previewRows,
                columnCount: widget.table.columnCount,
                selectedColumnIndex: _selectedColumnIndex,
              ),
              const SizedBox(height: 18),
              Text(
                'Resumo do lote',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryPill(
                    label: 'Total lido',
                    value: '${analysis.totalCodes}',
                  ),
                  _SummaryPill(
                    label: 'Novos',
                    value: '${analysis.newCodes.length}',
                  ),
                  _SummaryPill(
                    label: 'Duplicados',
                    value: '${analysis.duplicateCodes.length}',
                  ),
                  _SummaryPill(
                    label: 'Coluna usada',
                    value: analysis.columnLabel,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.tonal(
          onPressed: canImport
              ? () => Navigator.of(context).pop(
                    ImportDialogResult(
                      decision: ImportDialogDecision.onlyNew,
                      analysis: analysis,
                    ),
                  )
              : null,
          child: const Text('Importar somente os novos'),
        ),
        FilledButton(
          onPressed: canImport
              ? () => Navigator.of(context).pop(
                    ImportDialogResult(
                      decision: ImportDialogDecision.all,
                      analysis: analysis,
                    ),
                  )
              : null,
          child: const Text('Importar tudo mesmo assim'),
        ),
      ],
    );
  }
}

class _ImportPreviewTable extends StatelessWidget {
  const _ImportPreviewTable({
    required this.rows,
    required this.columnCount,
    required this.selectedColumnIndex,
  });

  final List<List<String>> rows;
  final int columnCount;
  final int selectedColumnIndex;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Text('Nao ha linhas de dados para mostrar na previa.');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: List<DataColumn>.generate(
          columnCount,
          (index) => DataColumn(
            label: Text(
              'Coluna ${ImportedTable.excelColumnLabel(index)}',
              style: TextStyle(
                color: index == selectedColumnIndex
                    ? AppColors.signalTeal
                    : null,
                fontWeight:
                    index == selectedColumnIndex ? FontWeight.w700 : null,
              ),
            ),
          ),
        ),
        rows: rows
            .map(
              (row) => DataRow(
                cells: List<DataCell>.generate(
                  columnCount,
                  (index) => DataCell(
                    Text(index < row.length ? row[index] : ''),
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.steel,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
