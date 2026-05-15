import 'dart:async';

import 'package:barcode_app/app/shell/shell_primitives.dart';
import 'package:barcode_app/app/theme/app_colors.dart';
import 'package:barcode_app/core/platform/platform_capabilities.dart';
import 'package:barcode_app/core/platform/file_download.dart';
import 'package:barcode_app/features/app_update/application/app_update_controller.dart';
import 'package:barcode_app/features/app_update/presentation/app_update_banner.dart';
import 'package:barcode_app/features/import/data/reading_import_picker.dart';
import 'package:barcode_app/features/inventory/application/inventory_import_controller.dart';
import 'package:barcode_app/features/inventory/application/inventory_export_builder.dart';
import 'package:barcode_app/features/inventory/data/inventory_repository.dart';
import 'package:barcode_app/features/inventory/domain/inventory_import_models.dart';
import 'package:barcode_app/features/inventory/domain/inventory_item.dart';
import 'package:barcode_app/features/inventory/export/inventory_audit_xlsx_export_service.dart';
import 'package:barcode_app/features/inventory/presentation/audit_status_summary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InventoryImportPage extends ConsumerWidget {
  const InventoryImportPage({
    super.key,
    this.state,
    this.onImportPressed,
    this.onExportPressed,
    this.onArchiveActiveAuditPressed,
    this.onSaveImportedItem,
    this.showWebMaintenanceActions,
  });

  final InventoryImportState? state;
  final VoidCallback? onImportPressed;
  final VoidCallback? onExportPressed;
  final VoidCallback? onArchiveActiveAuditPressed;
  final FutureOr<void> Function(InventoryItem item)? onSaveImportedItem;
  final bool? showWebMaintenanceActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InventoryImportState resolvedState =
        state ?? ref.watch(inventoryImportControllerProvider);
    final supportsUpdates =
        ref.watch(platformCapabilitiesProvider).supportsCameraScanning;
    final appUpdateState =
        supportsUpdates ? ref.watch(appUpdateControllerProvider) : null;
    final canUseWebMaintenance = (showWebMaintenanceActions ?? kIsWeb) &&
        resolvedState.activeAuditId != null &&
        !resolvedState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            SectionHeader(
              title: 'Auditoria de inventario',
              subtitle:
                  'Importe o XLSX ou XLS com as duas empresas, acompanhe a auditoria ativa e exporte o resultado separado por status.',
              actions: [
                FilledButton.icon(
                  onPressed: resolvedState.isLoading
                      ? null
                      : onImportPressed ?? () => _pickAndImport(ref),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Importar XLS/XLSX'),
                ),
                OutlinedButton.icon(
                  onPressed: resolvedState.activeAuditId == null
                      ? null
                      : onExportPressed ?? () => _exportActiveAudit(ref),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Exportar resultado'),
                ),
                if (canUseWebMaintenance)
                  OutlinedButton.icon(
                    onPressed: onArchiveActiveAuditPressed ??
                        () => _archiveActiveAudit(ref),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Apagar auditoria'),
                  ),
              ],
            ),
            if (appUpdateState?.shouldShowBanner ?? false) ...[
              const SizedBox(height: 16),
              AppUpdateBanner(
                state: appUpdateState!,
                onUpdateNow: () => ref
                    .read(appUpdateControllerProvider.notifier)
                    .startUpdate(),
                onDismiss: () => ref
                    .read(appUpdateControllerProvider.notifier)
                    .dismissForSession(),
                onRetry: () => ref
                    .read(appUpdateControllerProvider.notifier)
                    .startUpdate(),
              ),
            ],
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
                    correctCount: resolvedState.correctCount,
                    incorrectCount: resolvedState.incorrectCount,
                    notFoundCount: resolvedState.notFoundCount,
                    pendingCount: resolvedState.pendingCount,
                  ),
                ],
              ),
            ),
            if (resolvedState.errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ImportMessages(
                title: 'Erros na importacao',
                color: AppColors.faultRed,
                messages: resolvedState.errors,
              ),
            ],
            if (resolvedState.warnings.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ImportMessages(
                title: 'Avisos na importacao',
                color: AppColors.alertAmber,
                messages: resolvedState.warnings,
              ),
            ],
            if (canUseWebMaintenance &&
                resolvedState.importedItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ImportedItemsEditor(
                items: resolvedState.importedItems,
                onEdit: (item) => _editImportedItem(context, ref, item),
              ),
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

  Future<void> _archiveActiveAudit(WidgetRef ref) async {
    await ref
        .read(inventoryImportControllerProvider.notifier)
        .archiveActiveAudit();
  }

  Future<void> _editImportedItem(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
  ) async {
    final updated = await showDialog<InventoryItem>(
      context: context,
      builder: (_) => _InventoryItemEditDialog(item: item),
    );
    if (updated == null) {
      return;
    }
    final save = onSaveImportedItem;
    if (save != null) {
      await save(updated);
      return;
    }
    await ref
        .read(inventoryImportControllerProvider.notifier)
        .updateItem(updated);
  }
}

class _ImportMessages extends StatelessWidget {
  const _ImportMessages({
    required this.title,
    required this.color,
    required this.messages,
  });

  final String title;
  final Color color;
  final List<InventoryImportError> messages;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          ...messages.map(
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

class _ImportedItemsEditor extends StatelessWidget {
  const _ImportedItemsEditor({
    required this.items,
    required this.onEdit,
  });

  final List<InventoryItem> items;
  final ValueChanged<InventoryItem> onEdit;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Itens importados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.barcode} - ${item.bobbinCode} - ${item.warehouse}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => onEdit(item),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryItemEditDialog extends StatefulWidget {
  const _InventoryItemEditDialog({required this.item});

  final InventoryItem item;

  @override
  State<_InventoryItemEditDialog> createState() =>
      _InventoryItemEditDialogState();
}

class _InventoryItemEditDialogState extends State<_InventoryItemEditDialog> {
  late final TextEditingController _companyController;
  late final TextEditingController _bobbinController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _weightController;
  late final TextEditingController _warehouseController;

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController(text: widget.item.companyName);
    _bobbinController = TextEditingController(text: widget.item.bobbinCode);
    _descriptionController =
        TextEditingController(text: widget.item.itemDescription);
    _barcodeController = TextEditingController(text: widget.item.barcode);
    _weightController = TextEditingController(text: widget.item.weight);
    _warehouseController = TextEditingController(text: widget.item.warehouse);
  }

  @override
  void dispose() {
    _companyController.dispose();
    _bobbinController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _weightController.dispose();
    _warehouseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar item importado'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('Empresa', _companyController),
            _field('Codigo', _bobbinController),
            _field('Descricao', _descriptionController),
            _field('Codigo de barras', _barcodeController),
            _field('Peso', _weightController),
            _field('Armazem', _warehouseController),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              widget.item.copyWith(
                companyName: _companyController.text.trim(),
                bobbinCode: _bobbinController.text.trim(),
                itemDescription: _descriptionController.text.trim(),
                barcode: _barcodeController.text.trim(),
                weight: _weightController.text.trim(),
                warehouse: _warehouseController.text.trim(),
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
