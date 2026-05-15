import 'package:barcode_app/features/inventory/data/inventory_repository.dart';
import 'package:barcode_app/features/inventory/domain/inventory_audit.dart';
import 'package:barcode_app/features/inventory/domain/inventory_audit_result.dart';
import 'package:barcode_app/features/inventory/domain/inventory_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final inventoryAuditControllerProvider =
    AsyncNotifierProvider<InventoryAuditNotifier, InventoryAuditFlowState>(
  InventoryAuditNotifier.new,
);

class InventoryAuditNotifier extends AsyncNotifier<InventoryAuditFlowState> {
  late final InventoryAuditController _controller;

  @override
  Future<InventoryAuditFlowState> build() async {
    _controller = InventoryAuditController(
      repository: ref.read(inventoryRepositoryProvider),
    );
    return _controller.load();
  }

  Future<void> lookupBarcode(String barcode) async {
    state = const AsyncLoading();
    state = AsyncData(await _controller.lookupBarcode(barcode));
  }

  Future<void> markCorrect() async {
    final result = await _controller.markCorrect();
    state = AsyncData(
      _controller.currentState.copyWith(
        status: InventoryAuditFlowStatus.saved,
        existingResult: result,
      ),
    );
  }

  Future<void> markIncorrect({
    required Set<InventoryDiscrepancyField> fields,
    String? note,
  }) async {
    final result = await _controller.markIncorrect(fields: fields, note: note);
    state = AsyncData(
      _controller.currentState.copyWith(
        status: InventoryAuditFlowStatus.saved,
        existingResult: result,
      ),
    );
  }

  Future<void> markNotFound() async {
    final result = await _controller.markNotFound();
    state = AsyncData(
      _controller.currentState.copyWith(
        status: InventoryAuditFlowStatus.saved,
        existingResult: result,
      ),
    );
  }
}

class InventoryAuditController {
  InventoryAuditController({
    required InventoryRepository repository,
    Uuid uuid = const Uuid(),
    DateTime Function()? now,
  })  : _repository = repository,
        _uuid = uuid,
        _now = now ?? (() => DateTime.now().toUtc());

  final InventoryRepository _repository;
  final Uuid _uuid;
  final DateTime Function() _now;
  InventoryAuditFlowState _state = const InventoryAuditFlowState.ready();

  InventoryAuditFlowState get currentState => _state;

  Future<InventoryAuditFlowState> load() async {
    final audit = await _repository.fetchActiveAudit();
    _state = audit == null
        ? const InventoryAuditFlowState.noActiveAudit()
        : InventoryAuditFlowState.ready(
            activeAudit: audit,
            auditedResults: await _repository.fetchResults(audit.id),
          );
    if (audit != null) {
      await _repository.warmActiveAuditCache(audit.id);
    }
    return _state;
  }

  Future<InventoryAuditFlowState> lookupBarcode(String rawBarcode) async {
    final barcode = rawBarcode.trim();
    final audit = await _repository.fetchActiveAudit();
    if (audit == null) {
      _state = const InventoryAuditFlowState.noActiveAudit();
      return _state;
    }

    final auditedResults = await _repository.fetchResults(audit.id);
    final existingResult = await _repository.findResultByBarcode(
      audit.id,
      barcode,
    );
    if (existingResult != null) {
      _state = InventoryAuditFlowState(
        status: InventoryAuditFlowStatus.alreadyAudited,
        activeAudit: audit,
        scannedBarcode: barcode,
        item: await _repository.findItemByBarcode(audit.id, barcode),
        existingResult: existingResult,
        auditedResults: auditedResults,
      );
      return _state;
    }

    final item = await _repository.findItemByBarcode(audit.id, barcode);
    _state = InventoryAuditFlowState(
      status: item == null
          ? InventoryAuditFlowStatus.notFound
          : InventoryAuditFlowStatus.found,
      activeAudit: audit,
      scannedBarcode: barcode,
      item: item,
      existingResult: null,
      auditedResults: auditedResults,
    );
    return _state;
  }

  Future<InventoryAuditResult> markCorrect() async {
    final item = _requireFoundItem();
    final result = InventoryAuditResult.correct(
      id: _uuid.v4(),
      auditId: _state.activeAudit!.id,
      inventoryItemId: item.id,
      scannedBarcode: _state.scannedBarcode!,
      scannedAt: _now(),
    );
    return _save(result);
  }

  Future<InventoryAuditResult> markIncorrect({
    required Set<InventoryDiscrepancyField> fields,
    String? note,
  }) async {
    final item = _requireFoundItem();
    final result = InventoryAuditResult.incorrect(
      id: _uuid.v4(),
      auditId: _state.activeAudit!.id,
      inventoryItemId: item.id,
      scannedBarcode: _state.scannedBarcode!,
      discrepancyFields: fields,
      note: note,
      scannedAt: _now(),
    );
    return _save(result);
  }

  Future<InventoryAuditResult> markNotFound() async {
    if (_state.status != InventoryAuditFlowStatus.notFound ||
        _state.activeAudit == null ||
        _state.scannedBarcode == null) {
      throw StateError('Nao ha codigo desconhecido para registrar.');
    }
    final result = InventoryAuditResult.notFound(
      id: _uuid.v4(),
      auditId: _state.activeAudit!.id,
      scannedBarcode: _state.scannedBarcode!,
      scannedAt: _now(),
    );
    return _save(result);
  }

  InventoryItem _requireFoundItem() {
    if (_state.status != InventoryAuditFlowStatus.found ||
        _state.activeAudit == null ||
        _state.scannedBarcode == null ||
        _state.item == null) {
      throw StateError('Nao ha bobina encontrada aguardando decisao.');
    }
    return _state.item!;
  }

  Future<InventoryAuditResult> _save(InventoryAuditResult result) async {
    final saved = await _repository.saveResult(result);
    _state = _state.copyWith(
      status: InventoryAuditFlowStatus.saved,
      existingResult: saved,
      auditedResults: [..._state.auditedResults, saved],
    );
    return saved;
  }
}

enum InventoryAuditFlowStatus {
  noActiveAudit,
  ready,
  found,
  notFound,
  alreadyAudited,
  saved,
  error,
}

class InventoryAuditFlowState {
  const InventoryAuditFlowState({
    required this.status,
    this.activeAudit,
    this.scannedBarcode,
    this.item,
    this.existingResult,
    this.auditedResults = const [],
    this.errorMessage,
  });

  const InventoryAuditFlowState.ready({
    this.activeAudit,
    this.auditedResults = const [],
  })  : status = InventoryAuditFlowStatus.ready,
        scannedBarcode = null,
        item = null,
        existingResult = null,
        errorMessage = null;

  const InventoryAuditFlowState.noActiveAudit()
      : status = InventoryAuditFlowStatus.noActiveAudit,
        activeAudit = null,
        scannedBarcode = null,
        item = null,
        existingResult = null,
        auditedResults = const [],
        errorMessage = null;

  final InventoryAuditFlowStatus status;
  final InventoryAudit? activeAudit;
  final String? scannedBarcode;
  final InventoryItem? item;
  final InventoryAuditResult? existingResult;
  final List<InventoryAuditResult> auditedResults;
  final String? errorMessage;

  InventoryAuditFlowState copyWith({
    InventoryAuditFlowStatus? status,
    InventoryAudit? activeAudit,
    String? scannedBarcode,
    InventoryItem? item,
    InventoryAuditResult? existingResult,
    List<InventoryAuditResult>? auditedResults,
    String? errorMessage,
  }) {
    return InventoryAuditFlowState(
      status: status ?? this.status,
      activeAudit: activeAudit ?? this.activeAudit,
      scannedBarcode: scannedBarcode ?? this.scannedBarcode,
      item: item ?? this.item,
      existingResult: existingResult ?? this.existingResult,
      auditedResults: auditedResults ?? this.auditedResults,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
