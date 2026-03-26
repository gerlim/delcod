import 'dart:typed_data';

import 'package:barcode_app/app/shell/shell_primitives.dart';
import 'package:barcode_app/app/theme/app_colors.dart';
import 'package:barcode_app/core/platform/file_download.dart';
import 'package:barcode_app/core/platform/platform_capabilities.dart';
import 'package:barcode_app/features/export/data/pdf_export_service.dart';
import 'package:barcode_app/features/export/data/xlsx_export_service.dart';
import 'package:barcode_app/features/export/domain/export_readings_payload.dart';
import 'package:barcode_app/features/readings/application/readings_controller.dart';
import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/duplicate_decision.dart';
import 'package:barcode_app/features/readings/presentation/android_scanner_view.dart';
import 'package:barcode_app/features/readings/presentation/manual_entry_form.dart';
import 'package:barcode_app/features/sync/presentation/sync_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReadingsPage extends ConsumerStatefulWidget {
  const ReadingsPage({
    super.key,
    this.collectionId = 'global',
    this.collectionTitle = 'DelCod',
  });

  final String collectionId;
  final String collectionTitle;

  @override
  ConsumerState<ReadingsPage> createState() => _ReadingsPageState();
}

class _ReadingsPageState extends ConsumerState<ReadingsPage> {
  final Set<String> _selectedIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final readings = ref.watch(readingsControllerProvider);
    final capabilities = ref.watch(platformCapabilitiesProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 760;
    final desktop = screenWidth >= 1040;
    final contentWidth = compact ? double.infinity : 1260.0;

    return Scaffold(
      body: SafeArea(
        child: readings.when(
          data: (items) {
            final selectedItems = items
                .where((item) => _selectedIds.contains(item.id))
                .toList(growable: false);
            final exportItems = selectedItems.isEmpty ? items : selectedItems;
            final allSelected =
                items.isNotEmpty && selectedItems.length == items.length;

            return LayoutBuilder(
              builder: (context, constraints) {
                final resolvedWidth = compact
                    ? constraints.maxWidth
                    : constraints.maxWidth < contentWidth
                        ? constraints.maxWidth
                        : contentWidth;

                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: resolvedWidth,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 16 : 24,
                        compact ? 16 : 24,
                        compact ? 16 : 24,
                        compact ? 16 : 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PageHeader(
                            totalCount: items.length,
                            selectedCount: selectedItems.length,
                          ),
                          const SizedBox(height: 16),
                          const SyncStatusBanner(),
                          const SizedBox(height: 20),
                          Expanded(
                            child: desktop
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 388,
                                        child: SingleChildScrollView(
                                          child: Column(
                                            children: [
                                              _buildCaptureCard(
                                                context: context,
                                                capabilities: capabilities,
                                              ),
                                              const SizedBox(height: 16),
                                              _SummarySection(
                                                totalCount: items.length,
                                                selectedCount:
                                                    selectedItems.length,
                                              ),
                                              const SizedBox(height: 16),
                                              _ActionsSection(
                                                hasItems: items.isNotEmpty,
                                                allSelected: allSelected,
                                                hasSelection:
                                                    selectedItems.isNotEmpty,
                                                onToggleSelectAll: () {
                                                  setState(() {
                                                    if (allSelected) {
                                                      _selectedIds.clear();
                                                    } else {
                                                      _selectedIds
                                                        ..clear()
                                                        ..addAll(
                                                          items.map(
                                                            (item) => item.id,
                                                          ),
                                                        );
                                                    }
                                                  });
                                                },
                                                onExportXlsx:
                                                    exportItems.isEmpty
                                                        ? null
                                                        : () => _exportXlsx(
                                                              exportItems,
                                                            ),
                                                onExportPdf: exportItems.isEmpty
                                                    ? null
                                                    : () => _exportPdf(
                                                          exportItems,
                                                        ),
                                                onClearAll: items.isEmpty
                                                    ? null
                                                    : () => _confirmClearAll(
                                                          context,
                                                        ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: _ReadingsSection(
                                          items: items,
                                          selectedIds: _selectedIds,
                                          selectedCount: selectedItems.length,
                                          fillAvailableHeight: true,
                                          onSelectionChanged: (itemId, value) {
                                            setState(() {
                                              if (value) {
                                                _selectedIds.add(itemId);
                                              } else {
                                                _selectedIds.remove(itemId);
                                              }
                                            });
                                          },
                                          onEdit: _showEditDialog,
                                          onDelete: _deleteItem,
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView(
                                    children: [
                                      _buildCaptureCard(
                                        context: context,
                                        capabilities: capabilities,
                                      ),
                                      const SizedBox(height: 16),
                                      _SummarySection(
                                        totalCount: items.length,
                                        selectedCount: selectedItems.length,
                                      ),
                                      const SizedBox(height: 16),
                                      _ActionsSection(
                                        hasItems: items.isNotEmpty,
                                        allSelected: allSelected,
                                        hasSelection: selectedItems.isNotEmpty,
                                        onToggleSelectAll: () {
                                          setState(() {
                                            if (allSelected) {
                                              _selectedIds.clear();
                                            } else {
                                              _selectedIds
                                                ..clear()
                                                ..addAll(
                                                  items.map((item) => item.id),
                                                );
                                            }
                                          });
                                        },
                                        onExportXlsx: exportItems.isEmpty
                                            ? null
                                            : () => _exportXlsx(exportItems),
                                        onExportPdf: exportItems.isEmpty
                                            ? null
                                            : () => _exportPdf(exportItems),
                                        onClearAll: items.isEmpty
                                            ? null
                                            : () => _confirmClearAll(context),
                                      ),
                                      const SizedBox(height: 16),
                                      _ReadingsSection(
                                        items: items,
                                        selectedIds: _selectedIds,
                                        selectedCount: selectedItems.length,
                                        fillAvailableHeight: false,
                                        onSelectionChanged: (itemId, value) {
                                          setState(() {
                                            if (value) {
                                              _selectedIds.add(itemId);
                                            } else {
                                              _selectedIds.remove(itemId);
                                            }
                                          });
                                        },
                                        onEdit: _showEditDialog,
                                        onDelete: _deleteItem,
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(
            child: Text('Falha ao carregar os codigos'),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureCard({
    required BuildContext context,
    required PlatformCapabilities capabilities,
  }) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            capabilities.supportsCameraScanning
                ? 'Leitura por camera'
                : 'Entrada manual',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            capabilities.supportsCameraScanning
                ? 'Use a camera do celular para adicionar codigos direto na lista global.'
                : 'Digite ou cole o codigo manualmente para registrar na lista global.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.steel,
                ),
          ),
          const SizedBox(height: 18),
          if (capabilities.supportsCameraScanning)
            AndroidScannerView(
              onDetected: (value) => _addCode(
                value,
                source: 'camera',
              ),
            )
          else
            ManualEntryForm(
              onSubmit: (value) => _addCode(
                value,
                source: 'manual',
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addCode(
    String code, {
    required String source,
    bool forceDuplicate = false,
  }) async {
    final decision =
        await ref.read(readingsControllerProvider.notifier).addCode(
              code,
              source: source,
              forceDuplicate: forceDuplicate,
            );

    if (!mounted) {
      return;
    }

    if (decision == DuplicateDecision.warning) {
      final shouldContinue = await _showDuplicateDialog();
      if (shouldContinue == true) {
        await _addCode(
          code,
          source: source,
          forceDuplicate: true,
        );
      }
      return;
    }

    _showFeedback('Codigo adicionado');
  }

  Future<void> _showEditDialog(ReadingItem item) async {
    final controller = TextEditingController(text: item.code);
    final updatedCode = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar codigo'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Codigo',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (!mounted || updatedCode == null || updatedCode.isEmpty) {
      return;
    }

    final decision =
        await ref.read(readingsControllerProvider.notifier).updateCode(
              id: item.id,
              newCode: updatedCode,
            );

    if (decision == DuplicateDecision.warning) {
      final shouldContinue = await _showDuplicateDialog();
      if (shouldContinue == true) {
        await ref.read(readingsControllerProvider.notifier).updateCode(
              id: item.id,
              newCode: updatedCode,
              forceDuplicate: true,
            );
        if (mounted) {
          _showFeedback('Codigo atualizado');
        }
      }
      return;
    }

    _showFeedback('Codigo atualizado');
  }

  Future<void> _deleteItem(ReadingItem item) async {
    await ref.read(readingsControllerProvider.notifier).deleteCode(item.id);
    if (!mounted) {
      return;
    }
    setState(() => _selectedIds.remove(item.id));
    _showFeedback('Codigo removido');
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Limpar tudo'),
          content: const Text(
            'Essa acao vai remover todos os codigos ativos da lista global.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Limpar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(readingsControllerProvider.notifier).clearAll();
    if (!mounted) {
      return;
    }
    setState(() => _selectedIds.clear());
    _showFeedback('Lista limpa');
  }

  Future<bool?> _showDuplicateDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Codigo duplicado'),
          content: const Text(
            'Esse codigo ja esta na lista. Deseja continuar assim mesmo?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportXlsx(List<ReadingItem> items) async {
    final bytes = ref.read(xlsxExportServiceProvider).buildFile(
          ExportReadingsPayload(
            title: widget.collectionTitle,
            codes: items.map((item) => item.code).toList(growable: false),
          ),
        );
    await _downloadExport(
      bytes: bytes,
      filename: 'codigos.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      successMessage: 'Arquivo XLSX baixado',
    );
  }

  Future<void> _exportPdf(List<ReadingItem> items) async {
    final bytes = await ref.read(pdfExportServiceProvider).buildFile(
          ExportReadingsPayload(
            title: widget.collectionTitle,
            codes: items.map((item) => item.code).toList(growable: false),
          ),
        );
    await _downloadExport(
      bytes: bytes,
      filename: 'codigos.pdf',
      mimeType: 'application/pdf',
      successMessage: 'Arquivo PDF baixado',
    );
  }

  Future<void> _downloadExport({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    required String successMessage,
  }) async {
    final downloaded = await downloadBytes(
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
    );

    if (!mounted) {
      return;
    }

    _showFeedback(
      downloaded
          ? successMessage
          : 'Arquivo gerado. O navegador deve concluir o download em seguida.',
    );
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.totalCount,
    required this.selectedCount,
  });

  final int totalCount;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      title: 'DelCod',
      subtitle:
          'Leitura rapida no Android, digitacao manual no navegador e lista global compartilhada em tempo real.',
      actions: [
        _HeaderPill(
          label: 'Ativos',
          value: '$totalCount',
          icon: Icons.qr_code_2_rounded,
          color: AppColors.signalTeal,
        ),
        _HeaderPill(
          label: 'Selecionados',
          value: '$selectedCount',
          icon: Icons.checklist_rounded,
          color: AppColors.alertAmber,
        ),
      ],
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.steel,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.totalCount,
    required this.selectedCount,
  });

  final int totalCount;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo rapido',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Visao imediata da operacao atual, sem interromper a leitura.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.steel,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SummaryTile(
                label: 'Codigos ativos',
                value: '$totalCount',
                icon: Icons.inventory_2_outlined,
                color: AppColors.signalTeal,
              ),
              _SummaryTile(
                label: 'Selecionados',
                value: '$selectedCount',
                icon: Icons.task_alt_outlined,
                color: AppColors.alertAmber,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 148),
      decoration: BoxDecoration(
        color: AppColors.mist.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.steel,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActionsSection extends StatelessWidget {
  const _ActionsSection({
    required this.hasItems,
    required this.allSelected,
    required this.hasSelection,
    required this.onToggleSelectAll,
    required this.onExportXlsx,
    required this.onExportPdf,
    required this.onClearAll,
  });

  final bool hasItems;
  final bool allSelected;
  final bool hasSelection;
  final VoidCallback onToggleSelectAll;
  final VoidCallback? onExportXlsx;
  final VoidCallback? onExportPdf;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    final selectionLabel = allSelected ? 'Limpar selecao' : 'Selecionar todos';

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acoes da lista',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSelection
                ? 'As exportacoes vao considerar somente os itens marcados.'
                : 'Sem selecao ativa, a exportacao usa toda a lista.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.steel,
                ),
          ),
          const SizedBox(height: 16),
          _ActionButton(
            icon: allSelected
                ? Icons.deselect_outlined
                : Icons.select_all_rounded,
            label: selectionLabel,
            onPressed: hasItems ? onToggleSelectAll : null,
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.table_view_outlined,
            label: 'Exportar XLSX',
            onPressed: onExportXlsx,
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.picture_as_pdf_outlined,
            label: 'Exportar PDF',
            onPressed: onExportPdf,
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.delete_sweep_outlined,
            label: 'Limpar tudo',
            onPressed: onClearAll,
            destructive: true,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final foregroundColor =
        destructive ? AppColors.faultRed : AppColors.signalTeal;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: foregroundColor,
          side: BorderSide(
            color: destructive
                ? AppColors.faultRed.withOpacity(0.24)
                : AppColors.border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _ReadingsSection extends StatelessWidget {
  const _ReadingsSection({
    required this.items,
    required this.selectedIds,
    required this.selectedCount,
    required this.fillAvailableHeight,
    required this.onSelectionChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ReadingItem> items;
  final Set<String> selectedIds;
  final int selectedCount;
  final bool fillAvailableHeight;
  final void Function(String itemId, bool value) onSelectionChanged;
  final ValueChanged<ReadingItem> onEdit;
  final ValueChanged<ReadingItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lista global',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedCount > 0
                      ? '$selectedCount itens selecionados para exportacao'
                      : 'Todos os codigos registrados aparecem aqui em tempo real.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.steel,
                      ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              '${items.length} itens',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );

    Widget body;
    if (items.isEmpty) {
      body = fillAvailableHeight
          ? const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: _EmptyState(),
                ),
              ),
            )
          : const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 42),
              child: _EmptyState(),
            );
    } else {
      final listView = ListView.separated(
        padding: const EdgeInsets.all(16),
        shrinkWrap: !fillAvailableHeight,
        physics: fillAvailableHeight
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return _ReadingCard(
            item: item,
            selected: selectedIds.contains(item.id),
            onChanged: (selected) => onSelectionChanged(item.id, selected),
            onEdit: () => onEdit(item),
            onDelete: () => onDelete(item),
          );
        },
      );

      body = fillAvailableHeight ? Expanded(child: listView) : listView;
    }

    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          header,
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          body,
        ],
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({
    required this.item,
    required this.selected,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final ReadingItem item;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              onChanged: (value) => onChanged(value ?? false),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.code,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.source == 'camera'
                        ? 'Origem: camera'
                        : 'Origem: manual',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.steel,
                        ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                IconButton.outlined(
                  tooltip: 'Editar',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton.outlined(
                  tooltip: 'Excluir',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.qr_code_2_outlined,
          size: 52,
          color: AppColors.steel,
        ),
        const SizedBox(height: 16),
        Text(
          'Nenhum codigo registrado',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Use a leitura por camera no Android ou a entrada manual no navegador para comecar.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.steel,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
