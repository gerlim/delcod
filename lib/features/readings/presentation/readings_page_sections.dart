part of 'readings_page.dart';

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.totalCount,
    required this.selectedCount,
    required this.pendingCount,
  });

  final int totalCount;
  final int selectedCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      title: 'DelCod',
      subtitle:
          'Inventario rapido de bobinas com leitura no Android, digitacao no navegador e lista global compartilhada em tempo real.',
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
        _HeaderPill(
          label: 'Pendentes',
          value: '$pendingCount',
          icon: Icons.warning_amber_rounded,
          color: AppColors.faultRed,
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
    required this.pendingCount,
  });

  final int totalCount;
  final int selectedCount;
  final int pendingCount;

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
                label: 'Bobinas ativas',
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
              _SummaryTile(
                label: 'Sem armazem',
                value: '$pendingCount',
                icon: Icons.warning_amber_outlined,
                color: AppColors.faultRed,
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
    required this.onImportFile,
    required this.onAllocateWarehouse,
    required this.onExportXlsx,
    required this.onExportPdf,
    required this.onClearAll,
  });

  final bool hasItems;
  final bool allSelected;
  final bool hasSelection;
  final VoidCallback onToggleSelectAll;
  final VoidCallback onImportFile;
  final VoidCallback? onAllocateWarehouse;
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
            icon: Icons.file_upload_outlined,
            label: 'Importar arquivo',
            onPressed: onImportFile,
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: allSelected
                ? Icons.deselect_outlined
                : Icons.select_all_rounded,
            label: selectionLabel,
            onPressed: hasItems ? onToggleSelectAll : null,
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.warehouse_outlined,
            label: 'Alocar armazem',
            onPressed: onAllocateWarehouse,
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.table_view_outlined,
            label: 'Exportar Excel',
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
    required this.totalCount,
    required this.isSearchOpen,
    required this.searchQuery,
    required this.onOpenSearch,
    required this.onCloseSearch,
    required this.onSearchChanged,
    required this.searchController,
    required this.searchFocusNode,
    required this.fillAvailableHeight,
    required this.onSelectionChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ReadingItem> items;
  final Set<String> selectedIds;
  final int selectedCount;
  final int totalCount;
  final bool isSearchOpen;
  final String searchQuery;
  final VoidCallback onOpenSearch;
  final VoidCallback onCloseSearch;
  final ValueChanged<String> onSearchChanged;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final bool fillAvailableHeight;
  final void Function(String itemId, bool value) onSelectionChanged;
  final ValueChanged<ReadingItem> onEdit;
  final ValueChanged<ReadingItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final hasActiveSearch = searchQuery.trim().isNotEmpty;
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackedHeader = constraints.maxWidth < 520;
          final titleBlock = Column(
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
                    : isSearchOpen
                        ? 'Pesquise por lote ou armazem.'
                        : hasActiveSearch
                        ? 'Filtrando lotes por lote de bobina ou armazem.'
                        : 'Todos os lotes de bobina registrados aparecem aqui em tempo real.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.steel,
                    ),
              ),
            ],
          );

          final controls = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isSearchOpen)
                IconButton.outlined(
                  tooltip: 'Buscar lote ou armazem',
                  onPressed: onOpenSearch,
                  icon: const Icon(Icons.search_rounded),
                ),
              if (!isSearchOpen) const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.mist,
                  borderRadius: BorderRadius.circular(999),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  '${items.length} itens',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stackedHeader) ...[
                titleBlock,
                const SizedBox(height: 12),
                controls,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: titleBlock),
                    const SizedBox(width: 12),
                    controls,
                  ],
                ),
              if (isSearchOpen) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: searchController,
                  focusNode: searchFocusNode,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    labelText: 'Pesquisar lote ou armazem',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (searchQuery.isNotEmpty)
                          IconButton(
                            tooltip: 'Limpar busca',
                            onPressed: () {
                              searchController.clear();
                              onSearchChanged('');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                        IconButton(
                          tooltip: 'Fechar busca',
                          onPressed: onCloseSearch,
                          icon: const Icon(Icons.keyboard_arrow_up_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (hasActiveSearch) ...[
                const SizedBox(height: 10),
                Text(
                  '${items.length} de $totalCount itens encontrados',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.steel,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ],
          );
        },
      ),
    );

    Widget body;
    if (items.isEmpty) {
      body = fillAvailableHeight
          ? Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _EmptyState(
                      isSearchResultEmpty: hasActiveSearch,
                    ),
                  ),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
              child: _EmptyState(
                isSearchResultEmpty: hasActiveSearch,
              ),
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

    if (fillAvailableHeight && isSearchOpen) {
      final searchBody = items.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
              child: _EmptyState(
                isSearchResultEmpty: hasActiveSearch,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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

      return SectionCard(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          child: Column(
            children: [
              header,
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.border),
              searchBody,
            ],
          ),
        ),
      );
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
    final inventoryRecord = BobbinInventoryRecord.fromItem(item);
    final statusColor = inventoryRecord.hasWarehouseAllocated
        ? AppColors.signalTeal
        : AppColors.faultRed;

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
                    'Lote de Bobina',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.steel,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    inventoryRecord.lot,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ReadingMetaChip(
                        label: 'Armazem ${inventoryRecord.warehouseLabel}',
                        color: inventoryRecord.hasWarehouseAllocated
                            ? AppColors.signalTeal
                            : AppColors.faultRed,
                      ),
                      _ReadingMetaChip(
                        label: inventoryRecord.companyLabel,
                        color: inventoryRecord.companyName == null
                            ? AppColors.faultRed
                            : AppColors.alertAmber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    switch (item.source) {
                      'camera' => 'Origem: camera',
                      'import' => 'Origem: importacao',
                      _ => 'Origem: manual',
                    },
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.steel,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    inventoryRecord.statusLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
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
  const _EmptyState({
    this.isSearchResultEmpty = false,
  });

  final bool isSearchResultEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.qr_code_2_outlined,
          size: 52,
          color: AppColors.steel,
        ),
        const SizedBox(height: 16),
        Text(
          isSearchResultEmpty
              ? 'Nenhum lote encontrado para a pesquisa atual'
              : 'Nenhum lote registrado',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          isSearchResultEmpty
              ? 'Tente outro termo de pesquisa ou feche a busca para voltar a lista completa.'
              : 'Use a leitura por camera no Android ou a entrada manual no navegador para comecar o inventario de bobinas.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.steel,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _WarehouseAllocationField extends StatelessWidget {
  const _WarehouseAllocationField({
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Armazem',
      ),
      items: <DropdownMenuItem<String?>>[
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
      ],
      onChanged: onChanged,
    );
  }
}

class _WarehousePreviewText extends StatelessWidget {
  const _WarehousePreviewText({
    required this.warehouseCode,
  });

  final String? warehouseCode;

  @override
  Widget build(BuildContext context) {
    final companyName = BobbinInventoryRecord.deriveCompanyName(warehouseCode);
    final message = companyName == null
        ? 'Sem armazem selecionado, o lote entra como pendente.'
        : 'Empresa derivada automaticamente: $companyName';

    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: companyName == null
                ? AppColors.faultRed
                : AppColors.signalTeal,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _ReadingMetaChip extends StatelessWidget {
  const _ReadingMetaChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _EditReadingResult {
  const _EditReadingResult({
    required this.lot,
    required this.warehouseCode,
  });

  final String lot;
  final String? warehouseCode;
}

class _WarehouseAllocationDialog extends StatefulWidget {
  const _WarehouseAllocationDialog();

  @override
  State<_WarehouseAllocationDialog> createState() =>
      _WarehouseAllocationDialogState();
}

class _WarehouseAllocationDialogState extends State<_WarehouseAllocationDialog> {
  String? _selectedWarehouseCode;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Alocar armazem'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escolha o armazem que sera aplicado aos lotes selecionados.',
          ),
          const SizedBox(height: 16),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _selectedWarehouseCode == null
              ? null
              : () => Navigator.of(context).pop(_selectedWarehouseCode),
          child: const Text('Continuar'),
        ),
      ],
    );
  }
}

enum _WarehouseOverwriteDecision {
  applyPendingOnly,
  overwriteSelected,
}

class _WarehouseOverwriteDialog extends StatelessWidget {
  const _WarehouseOverwriteDialog({
    required this.previews,
    required this.nextWarehouseCode,
  });

  final List<_WarehouseOverwritePreview> previews;
  final String nextWarehouseCode;

  @override
  Widget build(BuildContext context) {
    final nextCompanyName =
        BobbinInventoryRecord.deriveCompanyName(nextWarehouseCode) ?? 'Pendente';

    return AlertDialog(
      title: const Text('Reescrever armazens existentes?'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${previews.length} lotes ja possuem armazem e seriam reescritos para $nextWarehouseCode · $nextCompanyName.',
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: previews
                      .map(
                        (preview) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.mist,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    preview.current.lot,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Atual: ${preview.current.warehouseLabel} · ${preview.current.companyLabel}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.steel,
                                        ),
                                  ),
                                  Text(
                                    'Novo: $nextWarehouseCode · $nextCompanyName',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.faultRed,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.tonal(
          onPressed: () => Navigator.of(context).pop(
            _WarehouseOverwriteDecision.applyPendingOnly,
          ),
          child: const Text('Somente pendentes'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            _WarehouseOverwriteDecision.overwriteSelected,
          ),
          child: const Text('Reescrever selecionados'),
        ),
      ],
    );
  }
}

class _WarehouseOverwritePreview {
  const _WarehouseOverwritePreview({
    required this.item,
    required this.current,
    required this.nextWarehouseCode,
  });

  final ReadingItem item;
  final BobbinInventoryRecord current;
  final String nextWarehouseCode;

  bool get shouldWarnAboutOverwrite =>
      current.hasWarehouseAllocated && current.warehouseCode != nextWarehouseCode;
}

