import 'dart:convert';

import 'package:barcode_app/features/inventory/data/inventory_audit_mapper.dart';
import 'package:barcode_app/features/inventory/data/inventory_audit_result_mapper.dart';
import 'package:barcode_app/features/inventory/data/inventory_item_mapper.dart';
import 'package:barcode_app/features/inventory/domain/inventory_audit.dart';
import 'package:barcode_app/features/inventory/domain/inventory_audit_result.dart';
import 'package:barcode_app/features/inventory/domain/inventory_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class InventoryLocalCache {
  Future<InventoryAudit?> readActiveAudit();
  Future<void> writeActiveAudit(InventoryAudit? audit);
  Future<List<InventoryItem>> readItems(String auditId);
  Future<void> writeItems(String auditId, List<InventoryItem> items);
  Future<List<InventoryAuditResult>> readResults(String auditId);
  Future<void> writeResults(String auditId, List<InventoryAuditResult> results);
  Future<List<InventoryAuditResult>> readPendingResults();
  Future<void> writePendingResults(List<InventoryAuditResult> results);
}

class SharedPreferencesInventoryLocalCache implements InventoryLocalCache {
  SharedPreferencesInventoryLocalCache(this._preferencesLoader);

  static const _activeAuditKey = 'v1.inventory.active_audit';
  static const _itemsPrefix = 'v1.inventory.items.';
  static const _resultsPrefix = 'v1.inventory.results.';
  static const _pendingResultsKey = 'v1.inventory.pending_results';

  final Future<SharedPreferences> Function() _preferencesLoader;

  @override
  Future<InventoryAudit?> readActiveAudit() async {
    final raw = (await _preferencesLoader()).getString(_activeAuditKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return InventoryAuditMapper.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  @override
  Future<void> writeActiveAudit(InventoryAudit? audit) async {
    final preferences = await _preferencesLoader();
    if (audit == null) {
      await preferences.remove(_activeAuditKey);
      return;
    }
    await preferences.setString(
      _activeAuditKey,
      jsonEncode(InventoryAuditMapper.toJson(audit)),
    );
  }

  @override
  Future<List<InventoryItem>> readItems(String auditId) async {
    return _readList(
      key: '$_itemsPrefix$auditId',
      fromJson: InventoryItemMapper.fromJson,
    );
  }

  @override
  Future<void> writeItems(String auditId, List<InventoryItem> items) {
    return _writeList(
      key: '$_itemsPrefix$auditId',
      values: items,
      toJson: InventoryItemMapper.toJson,
    );
  }

  @override
  Future<List<InventoryAuditResult>> readResults(String auditId) async {
    final cached = await _readList(
      key: '$_resultsPrefix$auditId',
      fromJson: InventoryAuditResultMapper.fromJson,
    );
    final pending = (await readPendingResults())
        .where((result) => result.auditId == auditId)
        .toList(growable: false);
    return _mergeResults(cached, pending);
  }

  @override
  Future<void> writeResults(
    String auditId,
    List<InventoryAuditResult> results,
  ) {
    return _writeList(
      key: '$_resultsPrefix$auditId',
      values: results,
      toJson: InventoryAuditResultMapper.toJson,
    );
  }

  @override
  Future<List<InventoryAuditResult>> readPendingResults() {
    return _readList(
      key: _pendingResultsKey,
      fromJson: InventoryAuditResultMapper.fromJson,
    );
  }

  @override
  Future<void> writePendingResults(List<InventoryAuditResult> results) {
    return _writeList(
      key: _pendingResultsKey,
      values: results,
      toJson: InventoryAuditResultMapper.toJson,
    );
  }

  Future<List<T>> _readList<T>({
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final raw = (await _preferencesLoader()).getString(key);
    if (raw == null || raw.isEmpty) {
      return <T>[];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  }

  Future<void> _writeList<T>({
    required String key,
    required List<T> values,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    await (await _preferencesLoader()).setString(
      key,
      jsonEncode(values.map(toJson).toList(growable: false)),
    );
  }
}

class MemoryInventoryLocalCache implements InventoryLocalCache {
  InventoryAudit? activeAudit;
  final Map<String, List<InventoryItem>> items = {};
  final Map<String, List<InventoryAuditResult>> results = {};
  List<InventoryAuditResult> pendingResults = [];

  @override
  Future<InventoryAudit?> readActiveAudit() async => activeAudit;

  @override
  Future<void> writeActiveAudit(InventoryAudit? audit) async {
    activeAudit = audit;
  }

  @override
  Future<List<InventoryItem>> readItems(String auditId) async {
    return List.of(items[auditId] ?? const <InventoryItem>[]);
  }

  @override
  Future<void> writeItems(String auditId, List<InventoryItem> nextItems) async {
    items[auditId] = List.of(nextItems);
  }

  @override
  Future<List<InventoryAuditResult>> readResults(String auditId) async {
    return _mergeResults(
      results[auditId] ?? const <InventoryAuditResult>[],
      pendingResults.where((result) => result.auditId == auditId),
    );
  }

  @override
  Future<void> writeResults(
    String auditId,
    List<InventoryAuditResult> nextResults,
  ) async {
    results[auditId] = List.of(nextResults);
  }

  @override
  Future<List<InventoryAuditResult>> readPendingResults() async {
    return List.of(pendingResults);
  }

  @override
  Future<void> writePendingResults(
    List<InventoryAuditResult> nextResults,
  ) async {
    pendingResults = List.of(nextResults);
  }
}

List<InventoryAuditResult> _mergeResults(
  Iterable<InventoryAuditResult> base,
  Iterable<InventoryAuditResult> pending,
) {
  final byBarcode = <String, InventoryAuditResult>{};
  for (final result in base.followedBy(pending)) {
    byBarcode['${result.auditId}:${result.scannedBarcode}'] = result;
  }
  return byBarcode.values.toList(growable: false);
}
