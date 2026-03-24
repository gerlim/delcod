import 'package:flutter/material.dart';

class ExportActions extends StatelessWidget {
  const ExportActions({
    super.key,
    required this.onExportXlsx,
    required this.onExportPdf,
  });

  final VoidCallback onExportXlsx;
  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        OutlinedButton.icon(
          onPressed: onExportXlsx,
          icon: const Icon(Icons.table_view_outlined),
          label: const Text('Exportar XLSX'),
        ),
        OutlinedButton.icon(
          onPressed: onExportPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Exportar PDF'),
        ),
      ],
    );
  }
}
