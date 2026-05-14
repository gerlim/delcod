import 'dart:typed_data';

import 'package:barcode_app/features/inventory/data/inventory_import_service.dart';
import 'package:barcode_app/features/inventory/data/inventory_repository.dart';
import 'package:barcode_app/features/inventory/domain/inventory_import_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final inventoryImportControllerProvider =
    NotifierProvider<InventoryImportNotifier, InventoryImportState>(
  InventoryImportNotifier.new,
);

class InventoryImportNotifier extends Notifier<InventoryImportState> {
  late final InventoryImportController _controller;

  @override
  InventoryImportState build() {
    _controller = InventoryImportController(
      importService: ref.read(inventoryImportServiceProvider),
      repository: ref.read(inventoryRepositoryProvider),
    );
    return const InventoryImportState.idle();
  }

  Future<void> importXlsx({
    required String filename,
    required Uint8List bytes,
  }) async {
    state = state.copyWith(isLoading: true, clearErrors: true);
    state = await _controller.importXlsx(filename: filename, bytes: bytes);
  }
}

final inventoryImportServiceProvider = Provider<InventoryImportService>((ref) {
  return const InventoryImportService();
});

class InventoryImportController {
  const InventoryImportController({
    required InventoryImportService importService,
    required InventoryRepository repository,
  })  : _importService = importService,
        _repository = repository;

  final InventoryImportService _importService;
  final InventoryRepository _repository;

  Future<InventoryImportState> importXlsx({
    required String filename,
    required Uint8List bytes,
  }) async {
    final validation = _importService.parseXlsx(
      filename: filename,
      bytes: bytes,
    );

    if (!validation.isValid) {
      return InventoryImportState(
        filename: filename,
        isLoading: false,
        importedCount: 0,
        activeAuditId: null,
        errors: validation.errors,
      );
    }

    final audit = await _repository.createAuditFromImport(
      title: 'Auditoria ${DateTime.now().toLocal().toIso8601String()}',
      sourceFilename: filename,
      drafts: validation.items,
    );

    return InventoryImportState(
      filename: filename,
      isLoading: false,
      importedCount: validation.items.length,
      activeAuditId: audit.id,
      errors: const <InventoryImportError>[],
    );
  }
}

class InventoryImportState {
  const InventoryImportState({
    required this.filename,
    required this.isLoading,
    required this.importedCount,
    required this.activeAuditId,
    required this.errors,
  });

  const InventoryImportState.idle()
      : filename = null,
        isLoading = false,
        importedCount = 0,
        activeAuditId = null,
        errors = const <InventoryImportError>[];

  final String? filename;
  final bool isLoading;
  final int importedCount;
  final String? activeAuditId;
  final List<InventoryImportError> errors;

  bool get hasErrors => errors.isNotEmpty;

  InventoryImportState copyWith({
    String? filename,
    bool? isLoading,
    int? importedCount,
    String? activeAuditId,
    List<InventoryImportError>? errors,
    bool clearErrors = false,
  }) {
    return InventoryImportState(
      filename: filename ?? this.filename,
      isLoading: isLoading ?? this.isLoading,
      importedCount: importedCount ?? this.importedCount,
      activeAuditId: activeAuditId ?? this.activeAuditId,
      errors: clearErrors ? const <InventoryImportError>[] : errors ?? this.errors,
    );
  }
}
