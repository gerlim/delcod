import 'package:barcode_app/features/inventory/domain/inventory_audit.dart';
import 'package:barcode_app/features/inventory/domain/inventory_audit_result.dart';
import 'package:barcode_app/features/inventory/domain/inventory_import_models.dart';
import 'package:barcode_app/features/inventory/domain/inventory_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(dataSource: InMemoryInventoryRemoteDataSource());
});

class InventoryRepository {
  InventoryRepository({
    required InventoryRemoteDataSource dataSource,
    Uuid uuid = const Uuid(),
    DateTime Function()? now,
  })  : _dataSource = dataSource,
        _uuid = uuid,
        _now = now ?? (() => DateTime.now().toUtc());

  final InventoryRemoteDataSource _dataSource;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<InventoryAudit> createAuditFromImport({
    required String title,
    required String sourceFilename,
    required List<InventoryItemDraft> drafts,
  }) async {
    final currentActive = await _dataSource.fetchActiveAudit();
    if (currentActive != null) {
      await _dataSource.archiveAudit(currentActive.id);
    }

    final timestamp = _now();
    final audit = InventoryAudit(
      id: _uuid.v4(),
      title: title.trim().isEmpty ? 'Auditoria de inventario' : title.trim(),
      status: InventoryAuditStatus.active,
      importedAt: timestamp,
      itemCount: drafts.length,
      sourceFilename: sourceFilename,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    await _dataSource.insertAudit(audit);

    final items = drafts
        .map(
          (draft) => InventoryItem(
            id: _uuid.v4(),
            auditId: audit.id,
            companyName: draft.companyName,
            bobbinCode: draft.bobbinCode,
            itemDescription: draft.itemDescription,
            barcode: draft.barcode.trim(),
            weight: draft.weight,
            warehouse: draft.warehouse,
            rowNumber: draft.rowNumber,
            rawPayload: draft.rawPayload,
          ),
        )
        .toList(growable: false);
    await _dataSource.insertItems(items);
    return audit;
  }

  Future<InventoryAudit?> fetchActiveAudit() {
    return _dataSource.fetchActiveAudit();
  }

  Future<List<InventoryItem>> fetchItems(String auditId) {
    return _dataSource.fetchItems(auditId);
  }

  Future<InventoryItem?> findItemByBarcode(
    String auditId,
    String barcode,
  ) {
    return _dataSource.findItemByBarcode(auditId, barcode.trim());
  }

  Future<InventoryAuditResult?> findResultByBarcode(
    String auditId,
    String barcode,
  ) {
    return _dataSource.findResultByBarcode(auditId, barcode.trim());
  }

  Future<InventoryAuditResult> saveResult(InventoryAuditResult result) async {
    final existing = await findResultByBarcode(
      result.auditId,
      result.scannedBarcode,
    );
    if (existing != null) {
      throw DuplicateInventoryAuditResultException(
        auditId: result.auditId,
        scannedBarcode: result.scannedBarcode,
      );
    }
    await _dataSource.insertResult(result);
    return result;
  }

  Future<InventoryAuditSnapshot> fetchSnapshot(String auditId) async {
    return InventoryAuditSnapshot(
      auditId: auditId,
      items: await _dataSource.fetchItems(auditId),
      results: await _dataSource.fetchResults(auditId),
    );
  }
}

abstract class InventoryRemoteDataSource {
  Future<InventoryAudit?> fetchActiveAudit();
  Future<void> archiveAudit(String auditId);
  Future<void> insertAudit(InventoryAudit audit);
  Future<void> insertItems(List<InventoryItem> items);
  Future<List<InventoryItem>> fetchItems(String auditId);
  Future<InventoryItem?> findItemByBarcode(String auditId, String barcode);
  Future<InventoryAuditResult?> findResultByBarcode(
    String auditId,
    String barcode,
  );
  Future<void> insertResult(InventoryAuditResult result);
  Future<List<InventoryAuditResult>> fetchResults(String auditId);
}

class InMemoryInventoryRemoteDataSource implements InventoryRemoteDataSource {
  final Map<String, InventoryAudit> _audits = <String, InventoryAudit>{};
  final Map<String, InventoryItem> _items = <String, InventoryItem>{};
  final Map<String, InventoryAuditResult> _results =
      <String, InventoryAuditResult>{};

  InventoryAudit? auditById(String id) => _audits[id];

  @override
  Future<void> archiveAudit(String auditId) async {
    final audit = _audits[auditId];
    if (audit == null) {
      return;
    }
    _audits[auditId] = InventoryAudit(
      id: audit.id,
      title: audit.title,
      status: InventoryAuditStatus.archived,
      importedAt: audit.importedAt,
      itemCount: audit.itemCount,
      sourceFilename: audit.sourceFilename,
      createdAt: audit.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<InventoryAudit?> fetchActiveAudit() async {
    for (final audit in _audits.values) {
      if (audit.isActive) {
        return audit;
      }
    }
    return null;
  }

  @override
  Future<List<InventoryItem>> fetchItems(String auditId) async {
    return _items.values
        .where((item) => item.auditId == auditId)
        .toList(growable: false);
  }

  @override
  Future<List<InventoryAuditResult>> fetchResults(String auditId) async {
    return _results.values
        .where((result) => result.auditId == auditId)
        .toList(growable: false);
  }

  @override
  Future<InventoryItem?> findItemByBarcode(String auditId, String barcode) async {
    for (final item in _items.values) {
      if (item.auditId == auditId && item.lookupBarcode == barcode.trim()) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<InventoryAuditResult?> findResultByBarcode(
    String auditId,
    String barcode,
  ) async {
    for (final result in _results.values) {
      if (result.auditId == auditId &&
          result.scannedBarcode == barcode.trim()) {
        return result;
      }
    }
    return null;
  }

  @override
  Future<void> insertAudit(InventoryAudit audit) async {
    _audits[audit.id] = audit;
  }

  @override
  Future<void> insertItems(List<InventoryItem> items) async {
    for (final item in items) {
      _items[item.id] = item;
    }
  }

  @override
  Future<void> insertResult(InventoryAuditResult result) async {
    _results[result.id] = result;
  }
}

class InventoryAuditSnapshot {
  const InventoryAuditSnapshot({
    required this.auditId,
    required this.items,
    required this.results,
  });

  final String auditId;
  final List<InventoryItem> items;
  final List<InventoryAuditResult> results;
}

class DuplicateInventoryAuditResultException implements Exception {
  const DuplicateInventoryAuditResultException({
    required this.auditId,
    required this.scannedBarcode,
  });

  final String auditId;
  final String scannedBarcode;

  @override
  String toString() {
    return 'Bobina ja auditada: $scannedBarcode na auditoria $auditId.';
  }
}
