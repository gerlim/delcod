import 'dart:typed_data';

import 'package:barcode_app/app/shell/shell_primitives.dart';
import 'package:barcode_app/app/theme/app_colors.dart';
import 'package:barcode_app/core/platform/file_download.dart';
import 'package:barcode_app/core/platform/platform_capabilities.dart';
import 'package:barcode_app/features/auth/application/current_session_provider.dart';
import 'package:barcode_app/features/companies/application/active_company_controller.dart';
import 'package:barcode_app/features/companies/domain/company_access.dart';
import 'package:barcode_app/features/export/data/pdf_export_service.dart';
import 'package:barcode_app/features/export/data/xlsx_export_service.dart';
import 'package:barcode_app/features/export/domain/export_collection_payload.dart';
import 'package:barcode_app/features/export/presentation/export_actions.dart';
import 'package:barcode_app/features/readings/application/readings_controller.dart';
import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/reading_input.dart';
import 'package:barcode_app/features/readings/presentation/android_scanner_view.dart';
import 'package:barcode_app/features/readings/presentation/manual_entry_form.dart';
import 'package:barcode_app/features/sync/presentation/sync_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ReadingsPage extends ConsumerWidget {
  const ReadingsPage({
    super.key,
    required this.collectionId,
    required this.collectionTitle,
  });

  final String collectionId;
  final String collectionTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readings = ref.watch(readingsControllerProvider(collectionId));
    final capabilities = ref.watch(platformCapabilitiesProvider);
    final availableCompanies =
        ref.watch(availableCompaniesProvider).valueOrNull ?? const [];
    final activeCompanyId =
        ref.watch(activeCompanyControllerProvider).valueOrNull;
    final currentRoles =
        ref.watch(currentSessionProvider)?.roles ?? const <String>{};
    final canManageReadings = _canManageReadings(currentRoles);
    final count = readings.valueOrNull?.length ?? 0;
    final compact = MediaQuery.sizeOf(context).width < 680;

    Future<void> registerReading(String code, String source) async {
      final decision = await ref
          .read(readingsControllerProvider(collectionId).notifier)
          .registerReading(
            ReadingInput(
              collectionId: collectionId,
              code: code,
              source: source,
            ),
          );

      if (!context.mounted) {
        return;
      }

      if (decision.name == 'warning') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Codigo ja lido nesta coleta'),
          ),
        );
      }
    }

    Future<void> exportXlsx(List<ReadingItem> items) async {
      final payload = _buildExportPayload(
        items: items,
        availableCompanies: availableCompanies,
        activeCompanyId: activeCompanyId,
      );
      final bytes = ref.read(xlsxExportServiceProvider).buildFile(payload);
      await _downloadExport(
        context: context,
        bytes: bytes,
        filename: '${_normalizeFileName(collectionTitle)}.xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        successMessage: 'Arquivo XLSX baixado',
      );
    }

    Future<void> exportPdf(List<ReadingItem> items) async {
      final payload = _buildExportPayload(
        items: items,
        availableCompanies: availableCompanies,
        activeCompanyId: activeCompanyId,
      );
      final bytes = await ref.read(pdfExportServiceProvider).buildFile(payload);
      if (!context.mounted) {
        return;
      }
      await _downloadExport(
        context: context,
        bytes: bytes,
        filename: '${_normalizeFileName(collectionTitle)}.pdf',
        mimeType: 'application/pdf',
        successMessage: 'Arquivo PDF baixado',
      );
    }

    Future<void> deleteReading(ReadingItem item) async {
      await ref
          .read(readingsControllerProvider(collectionId).notifier)
          .deleteReading(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: collectionTitle,
          subtitle:
              'Coleta ativa para leitura em tempo real, conferencia e exportacao.',
          actions: [
            OutlinedButton.icon(
              onPressed: () => context.go('/collections'),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Voltar para coletas'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SyncStatusBanner(),
        const SizedBox(height: 20),
        Expanded(
          child: readings.when(
            data: (items) => ListView(
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    SizedBox(
                      width: compact ? double.infinity : 460,
                      child: SectionCard(
                        child: capabilities.supportsCameraScanning
                            ? AndroidScannerView(
                                onDetected: (value) =>
                                    registerReading(value, 'camera'),
                              )
                            : ManualEntryForm(
                                onSubmit: (value) =>
                                    registerReading(value, 'manual'),
                              ),
                      ),
                    ),
                    SizedBox(
                      width: compact ? double.infinity : 280,
                      child: Column(
                        children: [
                          MetricCard(
                            label: 'Total',
                            value: '$count',
                            icon: Icons.qr_code_2_rounded,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total: $count',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 16),
                          SectionCard(
                            child: ExportActions(
                              onExportXlsx: () => exportXlsx(items),
                              onExportPdf: () => exportPdf(items),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SectionCard(
                  padding: EdgeInsets.zero,
                  child: items.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text('Nenhuma leitura registrada'),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Dismissible(
                              key: ValueKey(item.id),
                              direction: canManageReadings
                                  ? DismissDirection.endToStart
                                  : DismissDirection.none,
                              onDismissed: (_) => deleteReading(item),
                              background: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.faultRed,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                ),
                              ),
                              child: Card.outlined(
                                margin: EdgeInsets.zero,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.code,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(item.source),
                                      if (canManageReadings) ...[
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          children: [
                                            TextButton.icon(
                                              onPressed: () {},
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                              ),
                                              label: const Text('Editar'),
                                            ),
                                            TextButton.icon(
                                              onPressed: () => deleteReading(item),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                              ),
                                              label: const Text('Excluir'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('Falha ao carregar leituras')),
          ),
        ),
      ],
    );
  }

  ExportCollectionPayload _buildExportPayload({
    required List<ReadingItem> items,
    required List<CompanyAccess> availableCompanies,
    required String? activeCompanyId,
  }) {
    final companyName = _resolveCompanyName(
      availableCompanies: availableCompanies,
      activeCompanyId: activeCompanyId,
    );

    return ExportCollectionPayload(
      companyName: companyName,
      collectionTitle: collectionTitle,
      rows: items
          .map(
            (item) => ExportReadingRow(
              code: item.code,
              type: item.codeType,
              source: item.source,
              operatorName: item.operatorName,
              recordedAt: item.recordedAt,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<void> _downloadExport({
    required BuildContext context,
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

    if (!context.mounted) {
      return;
    }

    final message = downloaded
        ? successMessage
        : 'Arquivo gerado. Download automatico disponivel no navegador.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _normalizeFileName(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  String _resolveCompanyName({
    required List<CompanyAccess> availableCompanies,
    required String? activeCompanyId,
  }) {
    for (final company in availableCompanies) {
      if (company.companyId == activeCompanyId) {
        return company.companyName;
      }
    }

    if (availableCompanies.isNotEmpty) {
      return availableCompanies.first.companyName;
    }

    return 'Empresa ativa';
  }

  bool _canManageReadings(Set<String> roles) {
    return roles.contains('admin') ||
        roles.contains('gestor') ||
        roles.contains('manager') ||
        roles.contains('operador') ||
        roles.contains('operator');
  }
}
