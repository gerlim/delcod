import 'package:barcode_app/app/shell/shell_primitives.dart';
import 'package:barcode_app/app/theme/app_colors.dart';
import 'package:barcode_app/core/platform/file_download.dart';
import 'package:barcode_app/features/import/data/reading_import_picker.dart';
import 'package:barcode_app/features/inventory/application/inventory_import_controller.dart';
import 'package:barcode_app/features/inventory/application/inventory_export_builder.dart';
import 'package:barcode_app/features/inventory/data/inventory_repository.dart';
import 'package:barcode_app/features/inventory/domain/inventory_import_models.dart';
import 'package:barcode_app/features/inventory/export/inventory_audit_xlsx_export_service.dart';
import 'package:barcode_app/features/inventory/presentation/audit_status_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InventoryImportPage extends ConsumerWidget {
  const InventoryImportPage({
    super.key,
    this.state,
    this.onImportPressed,
    this.onExportPressed,
  });

  final InventoryImportState? state;
  final VoidCallback? onImportPressed;
  final VoidCallback? onExportPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InventoryImportState resolvedState =
        state ?? ref.watch(inventoryImportControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            SectionHeader(
              title: 'Auditoria de inventario',
              subtitle:
                  'Importe o XLSX com as duas empresas, acompanhe a auditoria ativa e exporte o resultado separado por status.',
              actions: [
                FilledButton.icon(
                  onPressed: resolvedState.isLoading
                      ? null
                      : onImportPressed ?? () => _pickAndImport(ref),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Importar XLSX'),
                ),
                OutlinedButton.icon(
                  onPressed: resolvedState.activeAuditId == null
                      ? null
                      : onExportPressed ?? () => _exportActiveAudit(ref),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Exportar resultado'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Auditoria ativa',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      StatusChip(
                        label: resolvedState.activeAuditId == null
                            ? 'Sem auditoria'
                            : 'Ativa',
                        color: resolvedState.activeAuditId == null
                            ? AppColors.alertAmber
                            : AppColors.safeGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    resolvedState.filename == null
                        ? 'Nenhuma planilha importada nesta sessao.'
                        : 'Arquivo: ${resolvedState.filename}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.steel,
                        ),
                  ),
                  const SizedBox(height: 18),
                  AuditStatusSummary(
                    importedCount: resolvedState.importedCount,
                  ),
                ],
              ),
            ),
            if (resolvedState.errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ImportErrors(errors: resolvedState.errors),
            ],
            const SizedBox(height: 16),
            const SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historico de auditorias',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'As auditorias anteriores permanecem salvas para consulta e exportacao quando conectadas ao Supabase.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndImport(WidgetRef ref) async {
    final picked = await ref.read(inventoryImportPickerProvider).pickFile();
    if (picked == null) {
      return;
    }
    await ref.read(inventoryImportControllerProvider.notifier).importXlsx(
          filename: picked.name,
          bytes: picked.bytes,
        );
  }

  Future<void> _exportActiveAudit(WidgetRef ref) async {
    final repository = ref.read(inventoryRepositoryProvider);
    final activeAudit = await repository.fetchActiveAudit();
    if (activeAudit == null) {
      return;
    }
    final snapshot = await repository.fetchSnapshot(activeAudit.id);
    final export = const InventoryExportBuilder().build(snapshot);
    final bytes = const InventoryAuditXlsxExportService().buildFile(export);
    await downloadBytes(
      bytes: bytes,
      filename: 'auditoria_inventario.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }
}

class _ImportErrors extends StatelessWidget {
  const _ImportErrors({required this.errors});

  final List<InventoryImportError> errors;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Erros na importacao',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.faultRed,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          ...errors.map(
            (error) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                error.rowNumber == null
                    ? error.message
                    : 'Linha ${error.rowNumber}: ${error.message}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
