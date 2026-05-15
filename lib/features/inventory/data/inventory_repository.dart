import 'dart:async';

import 'package:barcode_app/data/remote/supabase/supabase_client_provider.dart';
import 'package:barcode_app/features/inventory/data/inventory_audit_mapper.dart';
import 'package:barcode_app/features/inventory/data/inventory_audit_result_mapper.dart';
import 'package:barcode_app/features/inventory/data/inventory_item_mapper.dart';
import 'package:barcode_app/features/inventory/data/inventory_local_cache.dart';
import 'package:barcode_app/features/inventory/data/inventory_remote_contract.dart';
import 'package:barcode_app/features/inventory/domain/inventory_audit.dart';
import 'package:barcode_app/features/inventory/domain/inventory_audit_result.dart';
import 'package:barcode_app/features/inventory/domain/inventory_import_models.dart';
import 'package:barcode_app/features/inventory/domain/inventory_item.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';
import 'package:uuid/uuid.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final supabase = SupabaseClientRegistry.tryRead();
  return InventoryRepository(
    dataSource: supabase == null
        ? InMemoryInventoryRemoteDataSource()
        : SupabaseInventoryRemoteDataSource(supabase),
    localCache: SharedPreferencesInventoryLocalCache(
      SharedPreferences.getInstance,
    ),
    isOnline: _defaultOnlineCheck,
  );
});

Future<bool> _defaultOnlineCheck() async {
  try {
    final results = await Connectivity().checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  } on MissingPluginException {
    return true;
  }
}

class InventoryRepository {
  InventoryRepository({
    required InventoryRemoteDataSource dataSource,
    Uuid uuid = const Uuid(),
    DateTime Function()? now,
    InventoryLocalCache? localCache,
    Future<bool> Function()? isOnline,
  })  : _dataSource = dataSource,
        _uuid = uuid,
        _now = now ?? (() => DateTime.now().toUtc()),
        _localCache = localCache,
        _isOnline = isOnline ?? (() async => true);

  final InventoryRemoteDataSource _dataSource;
  final Uuid _uuid;
  final DateTime Function() _now;
  final InventoryLocalCache? _localCache;
  final Future<bool> Function() _isOnline;

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
    await _cacheActiveSnapshot(
      audit: audit,
      items: items,
      results: const <InventoryAuditResult>[],
      clearPending: true,
    );
    return audit;
  }

  Future<InventoryAudit?> fetchActiveAudit() async {
    if (await _isOnline()) {
      try {
        await syncPendingResults();
        final audit = await _dataSource.fetchActiveAudit();
        await _localCache?.writeActiveAudit(audit);
        return audit;
      } catch (_) {
        return _localCache?.readActiveAudit();
      }
    }
    return _localCache?.readActiveAudit();
  }

  Stream<InventoryAudit?> watchActiveAudit() {
    return _dataSource.watchActiveAudit().asyncMap((audit) async {
      await _localCache?.writeActiveAudit(audit);
      return audit;
    });
  }

  Future<void> archiveActiveAudit() async {
    final activeAudit = await _dataSource.fetchActiveAudit();
    if (activeAudit == null) {
      return;
    }
    await _dataSource.archiveAudit(activeAudit.id);
    await _localCache?.writeActiveAudit(null);
  }

  Future<List<InventoryItem>> fetchItems(String auditId) async {
    if (await _isOnline()) {
      try {
        final items = await _dataSource.fetchItems(auditId);
        await _localCache?.writeItems(auditId, items);
        return items;
      } catch (_) {
        return _localCache?.readItems(auditId) ?? const <InventoryItem>[];
      }
    }
    return _localCache?.readItems(auditId) ?? const <InventoryItem>[];
  }

  Future<void> updateItem(InventoryItem item) async {
    await _dataSource.updateItem(item);
    final items = await fetchItems(item.auditId);
    final updatedItems = items
        .map((current) => current.id == item.id ? item : current)
        .toList(growable: false);
    await _localCache?.writeItems(item.auditId, updatedItems);
  }

  Future<InventoryItem?> findItemByBarcode(
    String auditId,
    String barcode,
  ) async {
    final trimmed = barcode.trim();
    final cachedItems = await _localCache?.readItems(auditId);
    final cached = cachedItems?.where((item) => item.lookupBarcode == trimmed);
    if (cached != null && cached.isNotEmpty) {
      return cached.first;
    }
    if (!await _isOnline()) {
      return null;
    }
    final remote = await _dataSource.findItemByBarcode(auditId, trimmed);
    if (remote != null) {
      final existing = await _localCache?.readItems(auditId) ?? [];
      await _localCache?.writeItems(auditId, _upsertItem(existing, remote));
    }
    return remote;
  }

  Future<InventoryAuditResult?> findResultByBarcode(
    String auditId,
    String barcode,
  ) async {
    final trimmed = barcode.trim();
    final cached = (await _localCache?.readResults(auditId) ?? [])
        .where((result) => result.scannedBarcode == trimmed);
    if (cached.isNotEmpty) {
      return cached.first;
    }
    if (!await _isOnline()) {
      return null;
    }
    final remote = await _dataSource.findResultByBarcode(auditId, trimmed);
    if (remote != null) {
      await _cacheResult(remote);
    }
    return remote;
  }

  Future<List<InventoryAuditResult>> fetchResults(String auditId) async {
    if (await _isOnline()) {
      try {
        await syncPendingResults();
        final results = await _dataSource.fetchResults(auditId);
        await _localCache?.writeResults(auditId, results);
        return _localCache?.readResults(auditId) ?? results;
      } catch (_) {
        return _localCache?.readResults(auditId) ??
            const <InventoryAuditResult>[];
      }
    }
    return _localCache?.readResults(auditId) ?? const <InventoryAuditResult>[];
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
    if (await _isOnline()) {
      try {
        await _dataSource.insertResult(result);
        await _cacheResult(result);
        return result;
      } catch (_) {
        await _queuePendingResult(result);
        await _cacheResult(result);
        return result;
      }
    }
    await _queuePendingResult(result);
    await _cacheResult(result);
    return result;
  }

  Future<InventoryAuditSnapshot> fetchSnapshot(String auditId) async {
    return InventoryAuditSnapshot(
      auditId: auditId,
      items: await fetchItems(auditId),
      results: await fetchResults(auditId),
    );
  }

  Future<void> warmActiveAuditCache(String auditId) async {
    if (!await _isOnline()) {
      return;
    }
    try {
      final audit = await _dataSource.fetchActiveAudit();
      if (audit == null || audit.id != auditId) {
        return;
      }
      await _cacheActiveSnapshot(
        audit: audit,
        items: await _dataSource.fetchItems(auditId),
        results: await _dataSource.fetchResults(auditId),
      );
    } catch (_) {}
  }

  Future<int> pendingResultCount() async {
    return (await _localCache?.readPendingResults() ?? []).length;
  }

  Future<void> syncPendingResults() async {
    final cache = _localCache;
    if (cache == null || !await _isOnline()) {
      return;
    }
    final pending = await cache.readPendingResults();
    if (pending.isEmpty) {
      return;
    }
    final remaining = <InventoryAuditResult>[];
    for (final result in pending) {
      try {
        final existing = await _dataSource.findResultByBarcode(
          result.auditId,
          result.scannedBarcode,
        );
        if (existing == null) {
          await _dataSource.insertResult(result);
          await _cacheResult(result);
        } else {
          await _cacheResult(existing);
        }
      } catch (_) {
        remaining.add(result);
      }
    }
    await cache.writePendingResults(remaining);
  }

  Future<void> _cacheActiveSnapshot({
    required InventoryAudit audit,
    required List<InventoryItem> items,
    required List<InventoryAuditResult> results,
    bool clearPending = false,
  }) async {
    await _localCache?.writeActiveAudit(audit);
    await _localCache?.writeItems(audit.id, items);
    await _localCache?.writeResults(audit.id, results);
    if (clearPending) {
      await _localCache?.writePendingResults(const <InventoryAuditResult>[]);
    }
  }

  Future<void> _cacheResult(InventoryAuditResult result) async {
    final cache = _localCache;
    if (cache == null) {
      return;
    }
    final current = await cache.readResults(result.auditId);
    await cache.writeResults(result.auditId, _upsertResult(current, result));
  }

  Future<void> _queuePendingResult(InventoryAuditResult result) async {
    final cache = _localCache;
    if (cache == null) {
      return;
    }
    final current = await cache.readPendingResults();
    await cache.writePendingResults(_upsertResult(current, result));
  }

  List<InventoryItem> _upsertItem(
    List<InventoryItem> items,
    InventoryItem item,
  ) {
    final byId = <String, InventoryItem>{
      for (final current in items) current.id: current
    };
    byId[item.id] = item;
    return byId.values.toList(growable: false);
  }

  List<InventoryAuditResult> _upsertResult(
    List<InventoryAuditResult> results,
    InventoryAuditResult result,
  ) {
    final byBarcode = <String, InventoryAuditResult>{
      for (final current in results)
        '${current.auditId}:${current.scannedBarcode}': current,
    };
    byBarcode['${result.auditId}:${result.scannedBarcode}'] = result;
    return byBarcode.values.toList(growable: false);
  }
}

abstract class InventoryRemoteDataSource {
  Future<InventoryAudit?> fetchActiveAudit();
  Stream<InventoryAudit?> watchActiveAudit();
  Future<void> archiveAudit(String auditId);
  Future<void> insertAudit(InventoryAudit audit);
  Future<void> insertItems(List<InventoryItem> items);
  Future<void> updateItem(InventoryItem item);
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
  final StreamController<InventoryAudit?> _activeAuditController =
      StreamController<InventoryAudit?>.broadcast();

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
    _emitActiveAudit();
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
  Stream<InventoryAudit?> watchActiveAudit() async* {
    yield await fetchActiveAudit();
    yield* _activeAuditController.stream;
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
  Future<InventoryItem?> findItemByBarcode(
      String auditId, String barcode) async {
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
    _emitActiveAudit();
  }

  @override
  Future<void> insertItems(List<InventoryItem> items) async {
    for (final item in items) {
      _items[item.id] = item;
    }
  }

  @override
  Future<void> updateItem(InventoryItem item) async {
    _items[item.id] = item;
  }

  @override
  Future<void> insertResult(InventoryAuditResult result) async {
    _results[result.id] = result;
  }

  void _emitActiveAudit() {
    unawaited(fetchActiveAudit().then(_activeAuditController.add));
  }
}

class SupabaseInventoryRemoteDataSource implements InventoryRemoteDataSource {
  SupabaseInventoryRemoteDataSource(this._client);

  static const _pageSize = 1000;

  final SupabaseClient _client;

  @override
  Future<void> archiveAudit(String auditId) async {
    await _client.from(InventoryAuditsRemoteContract.tableName).update({
      InventoryAuditsRemoteContract.status:
          InventoryAuditStatus.archived.remoteValue,
    }).eq(InventoryAuditsRemoteContract.id, auditId);
  }

  @override
  Future<InventoryAudit?> fetchActiveAudit() async {
    final row = await _client
        .from(InventoryAuditsRemoteContract.tableName)
        .select()
        .eq(
          InventoryAuditsRemoteContract.status,
          InventoryAuditStatus.active.remoteValue,
        )
        .order(InventoryAuditsRemoteContract.importedAt, ascending: false)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return InventoryAuditMapper.fromJson(Map<String, dynamic>.from(row));
  }

  @override
  Stream<InventoryAudit?> watchActiveAudit() {
    return _client
        .from(InventoryAuditsRemoteContract.tableName)
        .stream(primaryKey: [InventoryAuditsRemoteContract.id])
        .order(InventoryAuditsRemoteContract.importedAt)
        .map((rows) {
          for (final row in rows.reversed) {
            final audit = InventoryAuditMapper.fromJson(
              Map<String, dynamic>.from(row),
            );
            if (audit.isActive) {
              return audit;
            }
          }
          return null;
        });
  }

  @override
  Future<List<InventoryItem>> fetchItems(String auditId) async {
    final rows = <dynamic>[];
    var from = 0;
    while (true) {
      final page = await _client
          .from(InventoryItemsRemoteContract.tableName)
          .select()
          .eq(InventoryItemsRemoteContract.auditId, auditId)
          .order(InventoryItemsRemoteContract.rowNumber)
          .range(from, from + _pageSize - 1);
      rows.addAll(page);
      if (page.length < _pageSize) {
        break;
      }
      from += _pageSize;
    }
    return rows
        .map<InventoryItem>(
          (row) => InventoryItemMapper.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
  }

  @override
  Future<List<InventoryAuditResult>> fetchResults(String auditId) async {
    final rows = <dynamic>[];
    var from = 0;
    while (true) {
      final page = await _client
          .from(InventoryAuditResultsRemoteContract.tableName)
          .select()
          .eq(InventoryAuditResultsRemoteContract.auditId, auditId)
          .order(InventoryAuditResultsRemoteContract.scannedAt)
          .range(from, from + _pageSize - 1);
      rows.addAll(page);
      if (page.length < _pageSize) {
        break;
      }
      from += _pageSize;
    }
    return rows
        .map<InventoryAuditResult>(
          (row) => InventoryAuditResultMapper.fromJson(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<InventoryItem?> findItemByBarcode(
      String auditId, String barcode) async {
    final row = await _client
        .from(InventoryItemsRemoteContract.tableName)
        .select()
        .eq(InventoryItemsRemoteContract.auditId, auditId)
        .eq(InventoryItemsRemoteContract.barcode, barcode.trim())
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return InventoryItemMapper.fromJson(Map<String, dynamic>.from(row));
  }

  @override
  Future<InventoryAuditResult?> findResultByBarcode(
    String auditId,
    String barcode,
  ) async {
    final row = await _client
        .from(InventoryAuditResultsRemoteContract.tableName)
        .select()
        .eq(InventoryAuditResultsRemoteContract.auditId, auditId)
        .eq(InventoryAuditResultsRemoteContract.scannedBarcode, barcode.trim())
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return InventoryAuditResultMapper.fromJson(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> insertAudit(InventoryAudit audit) async {
    await _client
        .from(InventoryAuditsRemoteContract.tableName)
        .insert(InventoryAuditMapper.toJson(audit));
  }

  @override
  Future<void> insertItems(List<InventoryItem> items) async {
    if (items.isEmpty) {
      return;
    }
    await _client.from(InventoryItemsRemoteContract.tableName).insert(
          items.map(InventoryItemMapper.toJson).toList(growable: false),
        );
  }

  @override
  Future<void> updateItem(InventoryItem item) async {
    await _client
        .from(InventoryItemsRemoteContract.tableName)
        .update(InventoryItemMapper.toJson(item))
        .eq(InventoryItemsRemoteContract.id, item.id);
  }

  @override
  Future<void> insertResult(InventoryAuditResult result) async {
    await _client
        .from(InventoryAuditResultsRemoteContract.tableName)
        .insert(InventoryAuditResultMapper.toJson(result));
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
