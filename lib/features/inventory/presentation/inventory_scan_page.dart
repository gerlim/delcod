import 'package:barcode_app/app/shell/shell_primitives.dart';
import 'package:barcode_app/app/theme/app_colors.dart';
import 'package:barcode_app/core/platform/platform_capabilities.dart';
import 'package:barcode_app/features/inventory/application/inventory_audit_controller.dart';
import 'package:barcode_app/features/inventory/domain/inventory_audit_result.dart';
import 'package:barcode_app/features/inventory/presentation/discrepancy_form.dart';
import 'package:barcode_app/features/inventory/presentation/inventory_item_card.dart';
import 'package:barcode_app/features/readings/presentation/android_scanner_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InventoryScanPage extends ConsumerStatefulWidget {
  const InventoryScanPage({
    super.key,
    this.state,
    this.onLookup,
    this.onMarkCorrect,
    this.onMarkIncorrect,
    this.onMarkNotFound,
  });

  final InventoryAuditFlowState? state;
  final ValueChanged<String>? onLookup;
  final VoidCallback? onMarkCorrect;
  final void Function(Set<InventoryDiscrepancyField> fields, String? note)?
      onMarkIncorrect;
  final VoidCallback? onMarkNotFound;

  @override
  ConsumerState<InventoryScanPage> createState() => _InventoryScanPageState();
}

class _InventoryScanPageState extends ConsumerState<InventoryScanPage> {
  final TextEditingController _manualController = TextEditingController();
  bool _showDiscrepancyForm = false;

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasInjectedState = widget.state != null;
    final asyncState = hasInjectedState
        ? AsyncData(widget.state!)
        : ref.watch(inventoryAuditControllerProvider);
    final supportsCameraScanning = hasInjectedState
        ? false
        : ref.watch(platformCapabilitiesProvider).supportsCameraScanning;

    return Scaffold(
      body: SafeArea(
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(
            child: Text('Falha ao carregar auditoria'),
          ),
          data: (state) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionHeader(
                title: 'Auditar bobina',
                subtitle:
                    'Escaneie ou digite o codigo de barras. Os dados importados nao podem ser editados.',
              ),
              const SizedBox(height: 16),
              if (supportsCameraScanning)
                SectionCard(
                  child: AndroidScannerView(onDetected: _lookup),
                ),
              const SizedBox(height: 12),
              _ManualLookup(
                controller: _manualController,
                onSubmit: _lookup,
              ),
              const SizedBox(height: 16),
              _buildStateContent(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateContent(InventoryAuditFlowState state) {
    switch (state.status) {
      case InventoryAuditFlowStatus.noActiveAudit:
        return const SectionCard(
          child: Text('Nenhuma auditoria ativa foi importada pela Web.'),
        );
      case InventoryAuditFlowStatus.ready:
        return const SectionCard(
          child: Text('Aguardando leitura de codigo de barras.'),
        );
      case InventoryAuditFlowStatus.found:
        final item = state.item;
        if (item == null) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InventoryItemCard(item: item),
            const SizedBox(height: 12),
            if (_showDiscrepancyForm)
              SectionCard(
                child: DiscrepancyForm(
                  onSubmit: (fields, note) {
                    widget.onMarkIncorrect?.call(fields, note);
                    ref
                        .read(inventoryAuditControllerProvider.notifier)
                        .markIncorrect(fields: fields, note: note);
                  },
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.safeGreen,
                      ),
                      onPressed: _markCorrect,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Correto'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.faultRed,
                      ),
                      onPressed: () {
                        setState(() => _showDiscrepancyForm = true);
                      },
                      icon: const Icon(Icons.error_outline),
                      label: const Text('Incorreto'),
                    ),
                  ),
                ],
              ),
          ],
        );
      case InventoryAuditFlowStatus.notFound:
        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusChip(
                label: 'Nao esta no banco',
                color: AppColors.alertAmber,
                icon: Icons.warning_amber_outlined,
              ),
              const SizedBox(height: 12),
              Text('Codigo lido: ${state.scannedBarcode ?? ''}'),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.alertAmber,
                ),
                onPressed: _markNotFound,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Registrar nao encontrado'),
              ),
            ],
          ),
        );
      case InventoryAuditFlowStatus.alreadyAudited:
        return const SectionCard(
          child: Text('Essa bobina ja foi auditada'),
        );
      case InventoryAuditFlowStatus.saved:
        return const SectionCard(
          child: Text('Resultado salvo'),
        );
      case InventoryAuditFlowStatus.error:
        return SectionCard(
          child: Text(state.errorMessage ?? 'Erro na auditoria'),
        );
    }
  }

  void _lookup(String barcode) {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) {
      return;
    }
    setState(() => _showDiscrepancyForm = false);
    widget.onLookup?.call(trimmed);
    if (widget.state == null) {
      ref.read(inventoryAuditControllerProvider.notifier).lookupBarcode(trimmed);
    }
  }

  void _markCorrect() {
    widget.onMarkCorrect?.call();
    if (widget.state == null) {
      ref.read(inventoryAuditControllerProvider.notifier).markCorrect();
    }
  }

  void _markNotFound() {
    widget.onMarkNotFound?.call();
    if (widget.state == null) {
      ref.read(inventoryAuditControllerProvider.notifier).markNotFound();
    }
  }
}

class _ManualLookup extends StatelessWidget {
  const _ManualLookup({
    required this.controller,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Codigo de barras manual',
                border: OutlineInputBorder(),
              ),
              onSubmitted: onSubmit,
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () => onSubmit(controller.text),
            icon: const Icon(Icons.search),
            label: const Text('Buscar'),
          ),
        ],
      ),
    );
  }
}
