import 'dart:typed_data';

import 'package:barcode_app/app/shell/shell_primitives.dart';
import 'package:barcode_app/app/theme/app_colors.dart';
import 'package:barcode_app/core/platform/file_download.dart';
import 'package:barcode_app/core/platform/platform_capabilities.dart';
import 'package:barcode_app/features/app_update/application/app_update_controller.dart';
import 'package:barcode_app/features/app_update/presentation/app_update_banner.dart';
import 'package:barcode_app/features/export/data/pdf_export_service.dart';
import 'package:barcode_app/features/export/data/xlsx_export_service.dart';
import 'package:barcode_app/features/import/data/reading_import_picker.dart';
import 'package:barcode_app/features/import/data/reading_import_service.dart';
import 'package:barcode_app/features/import/presentation/import_readings_dialog.dart';
import 'package:barcode_app/features/readings/application/readings_controller.dart';
import 'package:barcode_app/features/readings/application/readings_export_payload_builder.dart';
import 'package:barcode_app/features/readings/application/readings_list_filter.dart';
import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/bobbin_inventory_record.dart';
import 'package:barcode_app/features/readings/domain/duplicate_decision.dart';
import 'package:barcode_app/features/readings/presentation/android_scanner_view.dart';
import 'package:barcode_app/features/readings/presentation/manual_entry_form.dart';
import 'package:barcode_app/features/sync/presentation/sync_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'readings_page_sections.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String? _selectedWarehouseCode;
  bool _isSearchOpen = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readings = ref.watch(readingsControllerProvider);
    final capabilities = ref.watch(platformCapabilitiesProvider);
    final appUpdateState = capabilities.supportsCameraScanning
        ? ref.watch(appUpdateControllerProvider)
        : null;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 760;
    final desktop = screenWidth >= 1040;
    final useUnifiedMobileScroll =
        capabilities.supportsCameraScanning && !desktop;
    final contentWidth = compact ? double.infinity : 1260.0;

    return Scaffold(
      body: SafeArea(
        child: readings.when(
          data: (items) {
            final visibleItems = _filterItems(items);
            final selectedItems = visibleItems
                .where((item) => _selectedIds.contains(item.id))
                .toList(growable: false);
            final exportItems =
                selectedItems.isEmpty ? visibleItems : selectedItems;
            final allSelected =
                visibleItems.isNotEmpty &&
                selectedItems.length == visibleItems.length;

            return LayoutBuilder(
              builder: (context, constraints) {
                final resolvedWidth = compact
                    ? constraints.maxWidth
                    : constraints.maxWidth < contentWidth
                        ? constraints.maxWidth
                        : contentWidth;

                if (useUnifiedMobileScroll) {
                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: resolvedWidth,
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 16 : 24,
                          compact ? 16 : 24,
                          compact ? 16 : 24,
                          compact ? 16 : 24,
                        ),
                        children: [
                          _PageHeader(
                            totalCount: items.length,
                            selectedCount: selectedItems.length,
                            pendingCount: items
                                .map(BobbinInventoryRecord.fromItem)
                                .where((record) => !record.hasWarehouseAllocated)
                                .length,
                          ),
                          const SizedBox(height: 16),
                          const SyncStatusBanner(),
                          if (appUpdateState?.shouldShowBanner ?? false) ...[
                            const SizedBox(height: 12),
                            _buildAppUpdateBanner(appUpdateState!),
                          ],
                          const SizedBox(height: 20),
                          _buildCaptureCard(
                            context: context,
                            capabilities: capabilities,
                          ),
                          const SizedBox(height: 16),
                          _SummarySection(
                            totalCount: items.length,
                            selectedCount: selectedItems.length,
                            pendingCount: items
                                .map(BobbinInventoryRecord.fromItem)
                                .where((record) => !record.hasWarehouseAllocated)
                                .length,
                          ),
                          const SizedBox(height: 16),
                          _ActionsSection(
                            hasItems: items.isNotEmpty,
                            allSelected: allSelected,
                            hasSelection: selectedItems.isNotEmpty,
                            onToggleSelectAll: () {
                              setState(() {
                                if (allSelected) {
                                  _selectedIds.removeWhere(
                                    (id) => visibleItems.any(
                                      (item) => item.id == id,
                                    ),
                                  );
                                } else {
                                  _selectedIds.addAll(
                                    visibleItems.map((item) => item.id),
                                  );
                                }
                              });
                            },
                            onImportFile: () => _importFile(
                              existingCodes:
                                  items.map((item) => item.code).toSet(),
                            ),
                            onAllocateWarehouse: selectedItems.isEmpty
                                ? null
                                : () => _allocateWarehouseForSelection(
                                      selectedItems,
                                    ),
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
                            items: visibleItems,
                            selectedIds: _selectedIds,
                            selectedCount: selectedItems.length,
                            totalCount: items.length,
                            isSearchOpen: _isSearchOpen,
                            searchQuery: _searchQuery,
                            onOpenSearch: _openSearch,
                            onCloseSearch: () => _closeSearch(items),
                            onSearchChanged: (value) =>
                                _updateSearchQuery(value, items),
                            searchController: _searchController,
                            searchFocusNode: _searchFocusNode,
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
                  );
                }

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
                            pendingCount: items
                                .map(BobbinInventoryRecord.fromItem)
                                .where((record) => !record.hasWarehouseAllocated)
                                .length,
                          ),
                          const SizedBox(height: 16),
                          const SyncStatusBanner(),
                          if (appUpdateState?.shouldShowBanner ?? false) ...[
                            const SizedBox(height: 12),
                            _buildAppUpdateBanner(appUpdateState!),
                          ],
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
                                                pendingCount: items
                                                    .map(BobbinInventoryRecord.fromItem)
                                                    .where((record) =>
                                                        !record.hasWarehouseAllocated)
                                                    .length,
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
                                                      _selectedIds.removeWhere(
                                                        (id) => visibleItems.any(
                                                          (item) => item.id == id,
                                                        ),
                                                      );
                                                    } else {
                                                      _selectedIds.addAll(
                                                        visibleItems.map(
                                                          (item) => item.id,
                                                        ),
                                                      );
                                                    }
                                                  });
                                                },
                                                onImportFile: () => _importFile(
                                                  existingCodes: items
                                                      .map((item) => item.code)
                                                      .toSet(),
                                                ),
                                                onAllocateWarehouse:
                                                    selectedItems.isEmpty
                                                        ? null
                                                        : () => _allocateWarehouseForSelection(
                                                              selectedItems,
                                                            ),
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
                                          items: visibleItems,
                                          selectedIds: _selectedIds,
                                          selectedCount: selectedItems.length,
                                          totalCount: items.length,
                                          isSearchOpen: _isSearchOpen,
                                          searchQuery: _searchQuery,
                                          onOpenSearch: _openSearch,
                                          onCloseSearch: () =>
                                              _closeSearch(items),
                                          onSearchChanged: (value) =>
                                              _updateSearchQuery(value, items),
                                          searchController: _searchController,
                                          searchFocusNode: _searchFocusNode,
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
                                        pendingCount: items
                                            .map(BobbinInventoryRecord.fromItem)
                                            .where((record) =>
                                                !record.hasWarehouseAllocated)
                                            .length,
                                      ),
                                      const SizedBox(height: 16),
                                      _ActionsSection(
                                        hasItems: items.isNotEmpty,
                                        allSelected: allSelected,
                                        hasSelection: selectedItems.isNotEmpty,
                                        onToggleSelectAll: () {
                                          setState(() {
                                            if (allSelected) {
                                              _selectedIds.removeWhere(
                                                (id) => visibleItems.any(
                                                  (item) => item.id == id,
                                                ),
                                              );
                                            } else {
                                              _selectedIds.addAll(
                                                visibleItems.map(
                                                  (item) => item.id,
                                                ),
                                              );
                                            }
                                          });
                                        },
                                        onImportFile: () => _importFile(
                                          existingCodes: items
                                              .map((item) => item.code)
                                              .toSet(),
                                        ),
                                        onAllocateWarehouse:
                                            selectedItems.isEmpty
                                                ? null
                                                : () => _allocateWarehouseForSelection(
                                                      selectedItems,
                                                    ),
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
                                        items: visibleItems,
                                        selectedIds: _selectedIds,
                                        selectedCount: selectedItems.length,
                                        totalCount: items.length,
                                        isSearchOpen: _isSearchOpen,
                                        searchQuery: _searchQuery,
                                        onOpenSearch: _openSearch,
                                        onCloseSearch: () => _closeSearch(items),
                                        onSearchChanged: (value) =>
                                            _updateSearchQuery(value, items),
                                        searchController: _searchController,
                                        searchFocusNode: _searchFocusNode,
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
                ? 'Use a camera do celular para registrar lotes de bobina e escolha o armazem no mesmo painel.'
                : 'Digite ou cole o lote de bobina manualmente e defina o armazem quando souber.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.steel,
                ),
          ),
          const SizedBox(height: 18),
          if (capabilities.supportsCameraScanning)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AndroidScannerView(
                  onDetected: (value) => _addCode(
                    value,
                    source: 'camera',
                    warehouseCode: _selectedWarehouseCode,
                  ),
                ),
                const SizedBox(height: 14),
                _WarehouseAllocationField(
                  value: _selectedWarehouseCode,
                  onChanged: (value) {
                    setState(() {
                      _selectedWarehouseCode = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                _WarehousePreviewText(
                  warehouseCode: _selectedWarehouseCode,
                ),
              ],
            )
          else
            ManualEntryForm(
              onSubmit: (value) => _addCode(
                value,
                source: 'manual',
                warehouseCode: _selectedWarehouseCode,
              ),
              selectedWarehouseCode: _selectedWarehouseCode,
              onWarehouseChanged: (value) {
                setState(() {
                  _selectedWarehouseCode = value;
                });
              },
              warehouseOptions: _warehouseDropdownItems,
              companyPreview:
                  BobbinInventoryRecord.deriveCompanyName(_selectedWarehouseCode),
            ),
        ],
      ),
    );
  }

  void _openSearch() {
    setState(() {
      _isSearchOpen = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _closeSearch(List<ReadingItem> items) {
    setState(() {
      _isSearchOpen = false;
      _searchQuery = '';
      _searchController.clear();
      final visibleIds = items.map((item) => item.id).toSet();
      _selectedIds.removeWhere((id) => !visibleIds.contains(id));
    });
  }

  void _updateSearchQuery(String value, List<ReadingItem> items) {
    final nextQuery = value.trim();
    final visibleIds = ReadingsListFilter.apply(items, nextQuery)
        .map((item) => item.id)
        .toSet();
    setState(() {
      _searchQuery = nextQuery;
      _selectedIds.removeWhere((id) => !visibleIds.contains(id));
    });
  }

  List<ReadingItem> _filterItems(List<ReadingItem> items) {
    return ReadingsListFilter.apply(items, _searchQuery);
  }

  Future<void> _addCode(
    String code, {
    required String source,
    bool forceDuplicate = false,
    String? warehouseCode,
  }) async {
    final decision =
        await ref.read(readingsControllerProvider.notifier).addCode(
              code,
              source: source,
              forceDuplicate: forceDuplicate,
              warehouseCode: warehouseCode,
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

    final savedRecord = BobbinInventoryRecord(
      lot: code.trim(),
      warehouseCode:
          BobbinInventoryRecord.normalizeWarehouseCode(warehouseCode),
      companyName: BobbinInventoryRecord.deriveCompanyName(warehouseCode),
    );
    _showFeedback(
      savedRecord.hasWarehouseAllocated
          ? 'Lote de bobina adicionado'
          : 'Lote adicionado sem armazem. Ajuste depois na lista.',
    );
  }

  Future<void> _showEditDialog(ReadingItem item) async {
    final inventoryRecord = BobbinInventoryRecord.fromItem(item);
    final controller = TextEditingController(text: inventoryRecord.lot);
    String? selectedWarehouseCode = inventoryRecord.warehouseCode;
    final result = await showDialog<_EditReadingResult>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar lote de bobina'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Lote de Bobina',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _WarehouseAllocationField(
                    value: selectedWarehouseCode,
                    onChanged: (value) {
                      setState(() {
                        selectedWarehouseCode = value;
                      });
                    },
                  ),
                  if (selectedWarehouseCode != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            selectedWarehouseCode = null;
                          });
                        },
                        icon: const Icon(Icons.clear_outlined),
                        label: const Text('Remover armazem'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _WarehousePreviewText(
                    warehouseCode: selectedWarehouseCode,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    _EditReadingResult(
                      lot: controller.text.trim(),
                      warehouseCode: selectedWarehouseCode,
                    ),
                  ),
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();

    if (!mounted || result == null || result.lot.isEmpty) {
      return;
    }

    final decision =
        await ref.read(readingsControllerProvider.notifier).updateCode(
              id: item.id,
              newCode: result.lot,
              warehouseCode: result.warehouseCode,
              preserveExistingWarehouseIfUnset: false,
            );

    if (decision == DuplicateDecision.warning) {
      final shouldContinue = await _showDuplicateDialog();
      if (shouldContinue == true) {
        await ref.read(readingsControllerProvider.notifier).updateCode(
              id: item.id,
              newCode: result.lot,
              forceDuplicate: true,
              warehouseCode: result.warehouseCode,
              preserveExistingWarehouseIfUnset: false,
            );
        if (mounted) {
          _showFeedback('Lote de bobina atualizado');
        }
      }
      return;
    }

    _showFeedback('Lote de bobina atualizado');
  }

  Future<void> _deleteItem(ReadingItem item) async {
    await ref.read(readingsControllerProvider.notifier).deleteCode(item.id);
    if (!mounted) {
      return;
    }
    setState(() => _selectedIds.remove(item.id));
    _showFeedback('Lote removido');
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
            'Esse lote ja esta na lista. Deseja continuar assim mesmo?',
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
    final payload = ref.read(readingsExportPayloadBuilderProvider).build(
          title: widget.collectionTitle,
          items: items,
        );
    final bytes = ref.read(xlsxExportServiceProvider).buildFile(
          payload,
        );
    await _downloadExport(
      bytes: bytes,
      filename: 'lotes_bobina.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      successMessage: 'Arquivo XLSX baixado',
    );
  }

  Future<void> _exportPdf(List<ReadingItem> items) async {
    final payload = ref.read(readingsExportPayloadBuilderProvider).build(
          title: widget.collectionTitle,
          items: items,
        );
    final bytes = await ref.read(pdfExportServiceProvider).buildFile(
          payload,
        );
    await _downloadExport(
      bytes: bytes,
      filename: 'lotes_bobina.pdf',
      mimeType: 'application/pdf',
      successMessage: 'Arquivo PDF baixado',
    );
  }

  Future<void> _importFile({
    required Set<String> existingCodes,
  }) async {
    final pickedFile = await ref.read(readingImportPickerProvider).pickFile();
    if (pickedFile == null) {
      return;
    }

    try {
      final table = ref.read(readingImportServiceProvider).parseFile(
            filename: pickedFile.name,
            bytes: pickedFile.bytes,
          );

      if (!mounted) {
        return;
      }

      final result = await showDialog<ImportDialogResult>(
        context: context,
        builder: (context) {
          return ImportReadingsDialog(
            filename: pickedFile.name,
            table: table,
            existingCodes: existingCodes,
          );
        },
      );

      if (!mounted || result == null) {
        return;
      }

      final commitResult =
          await ref.read(readingsControllerProvider.notifier).importReadings(
                result.analysis.entries,
                includeDuplicates:
                    result.decision == ImportDialogDecision.all,
              );

      if (!mounted) {
        return;
      }

      _showFeedback(
        commitResult.skippedDuplicates > 0
            ? '${commitResult.importedCount} lotes importados. ${commitResult.skippedDuplicates} duplicados ignorados.'
            : '${commitResult.importedCount} lotes importados.',
      );
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }
      _showFeedback(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showFeedback('Nao foi possivel importar o arquivo.');
    }
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

  Future<void> _allocateWarehouseForSelection(
    List<ReadingItem> selectedItems,
  ) async {
    final warehouseCode = await showDialog<String?>(
      context: context,
      builder: (context) => const _WarehouseAllocationDialog(),
    );

    if (!mounted || warehouseCode == null) {
      return;
    }

    final normalizedWarehouseCode =
        BobbinInventoryRecord.normalizeWarehouseCode(warehouseCode);
    if (normalizedWarehouseCode == null) {
      return;
    }

    final overwriteCandidates = selectedItems
        .map(
          (item) => _WarehouseOverwritePreview(
            item: item,
            current: BobbinInventoryRecord.fromItem(item),
            nextWarehouseCode: normalizedWarehouseCode,
          ),
        )
        .where((preview) => preview.shouldWarnAboutOverwrite)
        .toList(growable: false);

    var overwriteExisting = false;
    if (overwriteCandidates.isNotEmpty) {
      final overwriteDecision = await showDialog<_WarehouseOverwriteDecision>(
        context: context,
        builder: (context) => _WarehouseOverwriteDialog(
          previews: overwriteCandidates,
          nextWarehouseCode: normalizedWarehouseCode,
        ),
      );

      if (!mounted || overwriteDecision == null) {
        return;
      }

      overwriteExisting =
          overwriteDecision == _WarehouseOverwriteDecision.overwriteSelected;
    }

    final result =
        await ref.read(readingsControllerProvider.notifier).allocateWarehouse(
              itemIds: selectedItems.map((item) => item.id).toList(growable: false),
              warehouseCode: normalizedWarehouseCode,
              overwriteExisting: overwriteExisting,
            );

    if (!mounted) {
      return;
    }

    if (result.updatedCount == 0) {
      _showFeedback('Nenhum lote precisou ser atualizado.');
      return;
    }

    _showFeedback(
      result.overwrittenCount > 0
          ? '${result.updatedCount} lotes atualizados. ${result.overwrittenCount} reescritos.'
          : '${result.updatedCount} lotes atualizados com armazem.',
    );
  }

  Widget _buildAppUpdateBanner(AppUpdateState state) {
    return AppUpdateBanner(
      state: state,
      onUpdateNow: () => ref.read(appUpdateControllerProvider.notifier).startUpdate(),
      onDismiss: () => ref.read(appUpdateControllerProvider.notifier).dismissForSession(),
      onRetry: () => ref.read(appUpdateControllerProvider.notifier).startUpdate(),
    );
  }

  List<DropdownMenuItem<String?>> get _warehouseDropdownItems {
    return <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(
        value: null,
        child: Text('Sem armazem definido'),
      ),
      ...BobbinInventoryRecord.warehouseOptions.map(
        (option) => DropdownMenuItem<String?>(
          value: option.code,
          child: Text(option.label),
        ),
      ),
    ];
  }
}
