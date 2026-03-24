import 'dart:typed_data';

import 'package:barcode_app/core/platform/file_download.dart';
import 'package:barcode_app/core/platform/platform_capabilities.dart';
import 'package:barcode_app/features/companies/application/active_company_controller.dart';
import 'package:barcode_app/features/companies/domain/company_access.dart';
import 'package:barcode_app/features/readings/application/readings_controller.dart';
import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/reading_input.dart';
import 'package:barcode_app/features/export/data/pdf_export_service.dart';
import 'package:barcode_app/features/export/data/xlsx_export_service.dart';
import 'package:barcode_app/features/export/domain/export_collection_payload.dart';
import 'package:barcode_app/features/export/presentation/export_actions.dart';
import 'package:barcode_app/features/readings/presentation/android_scanner_view.dart';
import 'package:barcode_app/features/readings/presentation/manual_entry_form.dart';
import 'package:barcode_app/features/sync/presentation/sync_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final count = readings.valueOrNull?.length ?? 0;

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
            content: Text('Código já lido nesta coleta'),
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
      await _downloadExport(
        context: context,
        bytes: bytes,
        filename: '${_normalizeFileName(collectionTitle)}.pdf',
        mimeType: 'application/pdf',
        successMessage: 'Arquivo PDF baixado',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(collectionTitle),
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),
          Expanded(
            child: readings.when(
              data: (items) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: ExportActions(
                      onExportXlsx: () => exportXlsx(items),
                      onExportPdf: () => exportPdf(items),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Total: $count'),
                  ),
                  Expanded(
                    child: items.isEmpty
                        ? const Center(
                            child: Text('Nenhuma leitura registrada'))
                        : ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return Dismissible(
                                key: ValueKey(item.id),
                                direction: DismissDirection.endToStart,
                                background: Container(color: Colors.red),
                                child: ListTile(
                                  title: Text(item.code),
                                  subtitle: Text(item.source),
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
      ),
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
        : 'Arquivo gerado. Download automático disponível no navegador.';

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
}
