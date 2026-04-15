import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:barcode_app/data/remote/supabase/supabase_client_provider.dart';
import 'package:barcode_app/features/readings/data/reading_item_json_mapper.dart';
import 'package:barcode_app/features/readings/data/readings_remote_contract.dart';
import 'package:barcode_app/features/readings/domain/reading_classification.dart';
import 'package:barcode_app/features/readings/domain/reading_item.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';
import 'package:uuid/uuid.dart';

export 'package:barcode_app/features/readings/domain/reading_item.dart';

final readingsRepositoryProvider = Provider<ReadingsRepository>((ref) {
  final repository = OfflineFirstReadingsRepository(
    connectivity: Connectivity(),
    preferencesLoader: SharedPreferences.getInstance,
    supabase: _tryReadSupabaseClient(),
    uuid: const Uuid(),
  );
  ref.onDispose(repository.dispose);
  return repository;
});

SupabaseClient? _tryReadSupabaseClient() {
  return SupabaseClientRegistry.tryRead();
}

abstract class ReadingsRepository {
  Stream<List<ReadingItem>> watchActive();
  Future<List<ReadingItem>> fetchActive();
  Future<bool> existsCode(
    String code, {
    String? excludingId,
  });
  Future<ReadingItem> addCode({
    required String code,
    required String source,
    ReadingClassification? classification,
    Map<String, dynamic>? metadataPayload,
  });
  Future<List<ReadingItem>> addCodesBatch({
    required List<String> codes,
    required String source,
    List<ReadingClassification>? classifications,
    List<Map<String, dynamic>?>? metadataPayloads,
  });
  Future<void> updateCode({
    required String id,
    required String newCode,
    ReadingClassification? classification,
    Map<String, dynamic>? metadataPayload,
  });
  Future<void> softDelete(String id);
  Future<void> clearAll();
  Future<bool> checkOnlineStatus();
  Stream<bool> watchOnlineStatus();
  Future<int> pendingCount();
  Future<void> syncNow();
  void dispose();
}

class OfflineFirstReadingsRepository implements ReadingsRepository {
  OfflineFirstReadingsRepository({
    required Connectivity connectivity,
    required Future<SharedPreferences> Function() preferencesLoader,
    required SupabaseClient? supabase,
    required Uuid uuid,
  })  : _connectivity = connectivity,
        _preferencesLoader = preferencesLoader,
        _supabase = supabase,
        _uuid = uuid {
    unawaited(_ensureInitialized());
  }

  static const _entriesKey = 'v2.shared_readings.entries';
  static const _pendingKey = 'v2.shared_readings.pending';
  static const _deviceIdKey = 'v2.shared_readings.device_id';

  final Connectivity _connectivity;
  final Future<SharedPreferences> Function() _preferencesLoader;
  final SupabaseClient? _supabase;
  final Uuid _uuid;

  final StreamController<List<ReadingItem>> _entriesController =
      StreamController<List<ReadingItem>>.broadcast();

  SharedPreferences? _preferences;
  List<ReadingItem> _entries = [];
  List<_PendingReadingMutation> _pending = [];
  StreamSubscription<List<Map<String, dynamic>>>? _remoteSubscription;
  Future<void>? _initialization;

  @override
  Stream<List<ReadingItem>> watchActive() => _entriesController.stream;

  @override
  Future<List<ReadingItem>> fetchActive() async {
    await _ensureInitialized();
    return _activeItems();
  }

  @override
  Future<bool> existsCode(
    String code, {
    String? excludingId,
  }) async {
    await _ensureInitialized();
    return _entries.any(
      (item) =>
          item.deletedAt == null && item.code == code && item.id != excludingId,
    );
  }

  @override
  Future<ReadingItem> addCode({
    required String code,
    required String source,
    ReadingClassification? classification,
    Map<String, dynamic>? metadataPayload,
  }) async {
    await _ensureInitialized();
    final now = DateTime.now().toUtc();
    final created = ReadingItem(
      id: _uuid.v4(),
      code: code,
      source: source,
      updatedAt: now,
      deletedAt: null,
      deviceId: await _deviceId(),
      classification: classification,
      metadataPayload: metadataPayload,
    );

    _upsertLocal(created);
    await _queueMutation(created);
    unawaited(syncNow());
    return created;
  }

  @override
  Future<List<ReadingItem>> addCodesBatch({
    required List<String> codes,
    required String source,
    List<ReadingClassification>? classifications,
    List<Map<String, dynamic>?>? metadataPayloads,
  }) async {
    await _ensureInitialized();
    if (codes.isEmpty) {
      return const <ReadingItem>[];
    }

    final now = DateTime.now().toUtc();
    final deviceId = await _deviceId();
    final created = codes
        .asMap()
        .entries
        .map(
          (entry) => ReadingItem(
            id: _uuid.v4(),
            code: entry.value,
            source: source,
            updatedAt: now.add(Duration(milliseconds: entry.key)),
            deletedAt: null,
            deviceId: deviceId,
            classification: entry.key < (classifications?.length ?? 0)
                ? classifications![entry.key]
                : null,
            metadataPayload: entry.key < (metadataPayloads?.length ?? 0)
                ? metadataPayloads![entry.key]
                : null,
          ),
        )
        .toList(growable: false);

    _entries.addAll(created);
    await _persistEntries();
    await _queueMutations(created);
    _emitEntries();
    unawaited(syncNow());
    return created;
  }

  @override
  Future<void> updateCode({
    required String id,
    required String newCode,
    ReadingClassification? classification,
    Map<String, dynamic>? metadataPayload,
  }) async {
    await _ensureInitialized();
    final current = _entries.firstWhere((item) => item.id == id);
    final updated = current.copyWith(
      code: newCode,
      updatedAt: DateTime.now().toUtc(),
      deletedAt: null,
      deviceId: await _deviceId(),
      classification: classification,
      metadataPayload: metadataPayload ?? current.metadataPayload,
    );
    _upsertLocal(updated);
    await _queueMutation(updated);
    unawaited(syncNow());
  }

  @override
  Future<void> softDelete(String id) async {
    await _ensureInitialized();
    final current = _entries.firstWhere((item) => item.id == id);
    final deleted = current.copyWith(
      updatedAt: DateTime.now().toUtc(),
      deletedAt: DateTime.now().toUtc(),
      deviceId: await _deviceId(),
    );
    _upsertLocal(deleted);
    await _queueMutation(deleted);
    unawaited(syncNow());
  }

  @override
  Future<void> clearAll() async {
    await _ensureInitialized();
    final now = DateTime.now().toUtc();
    final deviceId = await _deviceId();
    final active = _entries.where((item) => item.deletedAt == null).toList();

    for (final item in active) {
      _upsertLocal(
        item.copyWith(
          updatedAt: now,
          deletedAt: now,
          deviceId: deviceId,
        ),
      );
    }

    await _persistEntries();
    await _queueMutations(
      active
          .map(
            (item) => item.copyWith(
              updatedAt: now,
              deletedAt: now,
              deviceId: deviceId,
            ),
          )
          .toList(growable: false),
    );
    _emitEntries();
    unawaited(syncNow());
  }

  @override
  Future<bool> checkOnlineStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } on MissingPluginException {
      return true;
    }
  }

  @override
  Stream<bool> watchOnlineStatus() {
    return Stream<bool>.multi((controller) {
      StreamSubscription<List<ConnectivityResult>>? subscription;

      try {
        subscription = _connectivity.onConnectivityChanged.listen(
          (results) => controller.add(
            results.any((result) => result != ConnectivityResult.none),
          ),
          onError: (_) {},
        );
      } on MissingPluginException {
        controller.add(true);
      }

      controller.onCancel = () => subscription?.cancel();
    });
  }

  @override
  Future<int> pendingCount() async {
    await _ensureInitialized();
    return _pending.length;
  }

  @override
  Future<void> syncNow() async {
    await _ensureInitialized();
    if (!await checkOnlineStatus()) {
      return;
    }

    final supabase = _supabase;
    if (supabase == null) {
      return;
    }

    _remoteSubscription ??= supabase
        .from(ReadingsRemoteContract.tableName)
        .stream(primaryKey: [ReadingsRemoteContract.id])
        .order(ReadingsRemoteContract.updatedAt)
        .listen(
          _applyRemoteSnapshot,
          onError: (_, __) {},
        );

    if (_pending.isEmpty) {
      return;
    }

    final pendingSnapshot = List<_PendingReadingMutation>.of(_pending);
    for (final mutation in pendingSnapshot) {
      await supabase.from(ReadingsRemoteContract.tableName).upsert(
            ReadingItemJsonMapper.toJson(mutation.entry),
            onConflict: ReadingsRemoteContract.id,
          );
      _pending.removeWhere((entry) => entry.id == mutation.id);
      await _persistPending();
    }
  }

  Future<void> _ensureInitialized() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    _preferences = await _preferencesLoader();
    _entries = _readEntries();
    _pending = _readPending();
    _emitEntries();

    if (await checkOnlineStatus()) {
      unawaited(syncNow());
    }
  }

  List<ReadingItem> _readEntries() {
    final raw = _preferences?.getString(_entriesKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (entry) =>
              ReadingItemJsonMapper.fromJson(entry as Map<String, dynamic>),
        )
        .toList(growable: true);
  }

  List<_PendingReadingMutation> _readPending() {
    final raw = _preferences?.getString(_pendingKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (entry) =>
              _PendingReadingMutation.fromJson(entry as Map<String, dynamic>),
        )
        .toList(growable: true);
  }

  Future<String> _deviceId() async {
    await _ensureInitialized();
    final existing = _preferences?.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final created = _uuid.v4();
    await _preferences?.setString(_deviceIdKey, created);
    return created;
  }

  Future<void> _queueMutation(ReadingItem item) async {
    await _queueMutations([item]);
  }

  Future<void> _queueMutations(List<ReadingItem> items) async {
    for (final item in items) {
      _pending.removeWhere((entry) => entry.id == item.id);
      _pending.add(
        _PendingReadingMutation(
          id: item.id,
          entry: item,
        ),
      );
    }
    await _persistPending();
  }

  void _upsertLocal(ReadingItem item) {
    final existingIndex = _entries.indexWhere((entry) => entry.id == item.id);
    if (existingIndex >= 0) {
      _entries[existingIndex] = item;
    } else {
      _entries.add(item);
    }
    unawaited(_persistEntries());
    _emitEntries();
  }

  void _applyRemoteSnapshot(List<Map<String, dynamic>> rows) {
    final merged = <String, ReadingItem>{
      for (final local in _entries) local.id: local,
    };

    for (final row in rows) {
      final remote = ReadingItemJsonMapper.fromJson(row);
      final current = merged[remote.id];
      if (current == null || remote.updatedAt.isAfter(current.updatedAt)) {
        merged[remote.id] = remote;
      }
    }

    _entries = merged.values.toList(growable: true);
    unawaited(_persistEntries());
    _emitEntries();
  }

  Future<void> _persistEntries() async {
    await _ensureInitialized();
    final encoded = jsonEncode(
      _entries.map(ReadingItemJsonMapper.toJson).toList(growable: false),
    );
    await _preferences?.setString(_entriesKey, encoded);
  }

  Future<void> _persistPending() async {
    await _ensureInitialized();
    final encoded = jsonEncode(
      _pending.map((item) => item.toJson()).toList(growable: false),
    );
    await _preferences?.setString(_pendingKey, encoded);
  }

  List<ReadingItem> _activeItems() {
    final active = _entries.where((item) => item.deletedAt == null).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return active;
  }

  void _emitEntries() {
    if (!_entriesController.isClosed) {
      _entriesController.add(_activeItems());
    }
  }

  @override
  void dispose() {
    _remoteSubscription?.cancel();
    _entriesController.close();
  }
}

class _PendingReadingMutation {
  const _PendingReadingMutation({
    required this.id,
    required this.entry,
  });

  final String id;
  final ReadingItem entry;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entry': ReadingItemJsonMapper.toJson(entry),
    };
  }

  factory _PendingReadingMutation.fromJson(Map<String, dynamic> json) {
    return _PendingReadingMutation(
      id: json['id'] as String,
      entry: ReadingItemJsonMapper.fromJson(
        json['entry'] as Map<String, dynamic>,
      ),
    );
  }
}
