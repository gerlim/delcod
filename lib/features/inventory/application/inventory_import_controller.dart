import 'dart:async';
import 'dart:typed_data';

import 'package:barcode_app/features/inventory/application/inventory_export_builder.dart';
import 'package:barcode_app/features/inventory/data/inventory_import_service.dart';
import 'package:barcode_app/features/inventory/data/inventory_repository.dart';
import 'package:barcode_app/features/inventory/domain/inventory_audit.dart';
import 'package:barcode_app/features/inventory/domain/inventory_import_models.dart';
import 'package:barcode_app/features/inventory/domain/inventory_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final inventoryImportControllerProvider =
    NotifierProvider<InventoryImportNotifier, InventoryImportState>(
  InventoryImportNotifier.new,
);

class InventoryImportNotifier extends Notifier<InventoryImportState> {
  late final InventoryImportController _controller;
  bool _loadScheduled = false;
  StreamSubscription<InventoryAudit?>? _activeAuditSubscription;
  Timer? _activeAuditPollingTimer;

  @override
  InventoryImportState build() {
    _controller = InventoryImportController(
      importService: ref.read(inventoryImportServiceProvider),
      repository: ref.read(inventoryRepositoryProvider),
    );
    _startActiveAuditRefresh();
    if (!_loadScheduled) {
      _loadScheduled = true;
      Future<void>.microtask(loadActiveAudit);
    }
    return const InventoryImportState.idle();
  }

  void _startActiveAuditRefresh() {
    final repository = ref.read(inventoryRepositoryProvider);
    _activeAuditSubscription ??= repository.watchActiveAudit().listen(
          (_) => unawaited(loadActiveAudit()),
          onError: (_, __) {},
        );
    _activeAuditPollingTimer ??= Timer.periodic(
      const Duration(minutes: 5),
      (_) => unawaited(loadActiveAudit()),
    );
    ref.onDispose(() {
      _activeAuditSubscription?.cancel();
      _activeAuditPollingTimer?.cancel();
    });
  }

  Future<void> loadActiveAudit() async {
    state = state.copyWith(isLoading: true, clearErrors: true);
    state = await _controller.loadActiveAudit();
  }

  Future<void> importXlsx({
    required String filename,
    required Uint8List bytes,
  }) async {
    state = state.copyWith(isLoading: true, clearErrors: true);
    state = await _controller.importXlsx(filename: filename, bytes: bytes);
  }

  Future<void> archiveActiveAudit() async {
    state = state.copyWith(isLoading: true, clearErrors: true);
    state = await _controller.archiveActiveAudit();
  }

  Future<void> updateItem(InventoryItem item) async {
    state = state.copyWith(isLoading: true, clearErrors: true);
    state = await _controller.updateItem(item);
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

  Future<InventoryImportState> loadActiveAudit() async {
    final activeAudit = await _repository.fetchActiveAudit();
    if (activeAudit == null) {
      return const InventoryImportState.idle();
    }

    final snapshot = await _repository.fetchSnapshot(activeAudit.id);
    return InventoryImportState.fromSnapshot(
      activeAuditId: activeAudit.id,
      filename: activeAudit.sourceFilename,
      importedCount: activeAudit.itemCount,
      snapshot: snapshot,
    );
  }

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
        warnings: validation.warnings,
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
      correctCount: 0,
      incorrectCount: 0,
      notFoundCount: 0,
      pendingCount: validation.items.length,
      errors: const <InventoryImportError>[],
      warnings: validation.warnings,
    );
  }

  Future<InventoryImportState> archiveActiveAudit() async {
    await _repository.archiveActiveAudit();
    return const InventoryImportState.idle();
  }

  Future<InventoryImportState> updateItem(InventoryItem item) async {
    await _repository.updateItem(item);
    return loadActiveAudit();
  }
}

class InventoryImportState {
  const InventoryImportState({
    required this.filename,
    required this.isLoading,
    required this.importedCount,
    required this.activeAuditId,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.notFoundCount = 0,
    this.pendingCount = 0,
    this.importedItems = const [],
    required this.errors,
    this.warnings = const <InventoryImportError>[],
  });

  const InventoryImportState.idle()
      : filename = null,
        isLoading = false,
        importedCount = 0,
        activeAuditId = null,
        correctCount = 0,
        incorrectCount = 0,
        notFoundCount = 0,
        pendingCount = 0,
        importedItems = const [],
        errors = const <InventoryImportError>[],
        warnings = const <InventoryImportError>[];

  factory InventoryImportState.fromSnapshot({
    required String activeAuditId,
    required String filename,
    required int importedCount,
    required InventoryAuditSnapshot snapshot,
  }) {
    final export = const InventoryExportBuilder().build(snapshot);
    return InventoryImportState(
      filename: filename,
      isLoading: false,
      importedCount: importedCount,
      activeAuditId: activeAuditId,
      correctCount: export.correct.length,
      incorrectCount: export.incorrect.length,
      notFoundCount: export.notFound.length,
      pendingCount: export.pending.length,
      importedItems: snapshot.items,
      errors: const <InventoryImportError>[],
      warnings: const <InventoryImportError>[],
    );
  }

  final String? filename;
  final bool isLoading;
  final int importedCount;
  final String? activeAuditId;
  final int correctCount;
  final int incorrectCount;
  final int notFoundCount;
  final int pendingCount;
  final List<InventoryItem> importedItems;
  final List<InventoryImportError> errors;
  final List<InventoryImportError> warnings;

  bool get hasErrors => errors.isNotEmpty;

  InventoryImportState copyWith({
    String? filename,
    bool? isLoading,
    int? importedCount,
    String? activeAuditId,
    int? correctCount,
    int? incorrectCount,
    int? notFoundCount,
    int? pendingCount,
    List<InventoryItem>? importedItems,
    List<InventoryImportError>? errors,
    List<InventoryImportError>? warnings,
    bool clearErrors = false,
  }) {
    return InventoryImportState(
      filename: filename ?? this.filename,
      isLoading: isLoading ?? this.isLoading,
      importedCount: importedCount ?? this.importedCount,
      activeAuditId: activeAuditId ?? this.activeAuditId,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      notFoundCount: notFoundCount ?? this.notFoundCount,
      pendingCount: pendingCount ?? this.pendingCount,
      importedItems: importedItems ?? this.importedItems,
      errors:
          clearErrors ? const <InventoryImportError>[] : errors ?? this.errors,
      warnings: clearErrors
          ? const <InventoryImportError>[]
          : warnings ?? this.warnings,
    );
  }
}
