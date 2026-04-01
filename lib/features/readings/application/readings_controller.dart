import 'dart:async';

import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/duplicate_decision.dart';
import 'package:barcode_app/features/readings/domain/import_commit_result.dart';
import 'package:barcode_app/features/readings/domain/bobbin_inventory_record.dart';
import 'package:barcode_app/features/readings/domain/reading_classification.dart';
import 'package:barcode_app/features/readings/domain/reading_type_classifier.dart';
import 'package:barcode_app/features/readings/domain/warehouse_allocation_result.dart';
import 'package:barcode_app/features/import/data/reading_import_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final readingsControllerProvider =
    AsyncNotifierProvider<ReadingsController, List<ReadingItem>>(
  ReadingsController.new,
);

class ReadingsController extends AsyncNotifier<List<ReadingItem>> {
  StreamSubscription<List<ReadingItem>>? _subscription;

  @override
  Future<List<ReadingItem>> build() async {
    final repository = ref.read(readingsRepositoryProvider);
    _subscription = repository.watchActive().listen((items) {
      state = AsyncData(items);
    });
    ref.onDispose(() => _subscription?.cancel());
    return repository.fetchActive();
  }

  Future<DuplicateDecision> addCode(
    String code, {
    required String source,
    bool forceDuplicate = false,
    String? warehouseCode,
  }) async {
    final normalized = code.trim();
    if (normalized.isEmpty) {
      return DuplicateDecision.saved;
    }

    final repository = ref.read(readingsRepositoryProvider);
    final exists = await repository.existsCode(normalized);
    if (exists && !forceDuplicate) {
      return DuplicateDecision.warning;
    }

    final classification = _classify(normalized);
    await repository.addCode(
      code: normalized,
      source: source,
      classification: classification,
      metadataPayload: BobbinInventoryRecord.buildMetadata(
        lot: normalized,
        warehouseCode: warehouseCode,
      ),
    );
    state = AsyncData(await repository.fetchActive());
    return DuplicateDecision.saved;
  }

  Future<DuplicateDecision> updateCode({
    required String id,
    required String newCode,
    bool forceDuplicate = false,
    String? warehouseCode,
  }) async {
    final normalized = newCode.trim();
    if (normalized.isEmpty) {
      return DuplicateDecision.saved;
    }

    final repository = ref.read(readingsRepositoryProvider);
    final currentItems = await repository.fetchActive();
    final current = _findItemById(currentItems, id);
    final exists = await repository.existsCode(
      normalized,
      excludingId: id,
    );
    if (exists && !forceDuplicate) {
      return DuplicateDecision.warning;
    }

    final classification = _classify(normalized);
    await repository.updateCode(
      id: id,
      newCode: normalized,
      classification: classification,
      metadataPayload: BobbinInventoryRecord.buildMetadata(
        lot: normalized,
        warehouseCode: warehouseCode ??
            (current == null
                ? null
                : BobbinInventoryRecord.fromItem(current).warehouseCode),
        seed: current?.metadataPayload,
      ),
    );
    state = AsyncData(await repository.fetchActive());
    return DuplicateDecision.saved;
  }

  Future<void> deleteCode(String id) async {
    final repository = ref.read(readingsRepositoryProvider);
    await repository.softDelete(id);
    state = AsyncData(await repository.fetchActive());
  }

  Future<void> clearAll() async {
    final repository = ref.read(readingsRepositoryProvider);
    await repository.clearAll();
    state = AsyncData(await repository.fetchActive());
  }

  Future<ImportCommitResult> importCodes(
    List<String> codes, {
    required bool includeDuplicates,
  }) async {
    return importReadings(
      codes
          .map((code) => ImportedReadingEntry(code: code))
          .toList(growable: false),
      includeDuplicates: includeDuplicates,
    );
  }

  Future<ImportCommitResult> importReadings(
    List<ImportedReadingEntry> entries, {
    required bool includeDuplicates,
  }) async {
    final normalizedEntries = entries
        .map(
          (entry) => ImportedReadingEntry(
            code: entry.code.replaceAll(RegExp(r'\s+'), '').trim(),
            metadata: entry.metadata,
          ),
        )
        .where((entry) => entry.code.isNotEmpty)
        .toList(growable: false);

    if (normalizedEntries.isEmpty) {
      return const ImportCommitResult(
        importedCount: 0,
        skippedDuplicates: 0,
      );
    }

    final repository = ref.read(readingsRepositoryProvider);
    final activeItems = await repository.fetchActive();
    final existingCodes = activeItems.map((item) => item.code).toSet();
    final seenInImport = <String>{};
    final codesToImport = <String>[];
    final classifications = <ReadingClassification>[];
    final metadataPayloads = <Map<String, dynamic>?>[];
    var skippedDuplicates = 0;

    for (final entry in normalizedEntries) {
      final code = entry.code;
      final duplicate =
          existingCodes.contains(code) || seenInImport.contains(code);
      final metadataPayload = BobbinInventoryRecord.buildMetadata(
        lot: code,
        warehouseCode: entry.metadata['warehouse_code'],
        seed: Map<String, dynamic>.from(entry.metadata),
      );

      if (duplicate) {
        if (includeDuplicates) {
          codesToImport.add(code);
          classifications.add(_classify(code));
          metadataPayloads.add(metadataPayload);
        } else {
          skippedDuplicates += 1;
        }
        continue;
      }

      seenInImport.add(code);
      codesToImport.add(code);
      classifications.add(_classify(code));
      metadataPayloads.add(metadataPayload);
    }

    if (codesToImport.isNotEmpty) {
      await repository.addCodesBatch(
        codes: codesToImport,
        source: 'import',
        classifications: classifications,
        metadataPayloads: metadataPayloads,
      );
    }

    state = AsyncData(await repository.fetchActive());
    return ImportCommitResult(
      importedCount: codesToImport.length,
      skippedDuplicates: includeDuplicates ? 0 : skippedDuplicates,
    );
  }

  Future<void> reprocessClassifications() async {
    final repository = ref.read(readingsRepositoryProvider);
    final activeItems = await repository.fetchActive();
    for (final item in activeItems) {
      await repository.updateCode(
        id: item.id,
        newCode: item.code,
        classification: _classify(item.code),
        metadataPayload: item.metadataPayload,
      );
    }
    state = AsyncData(await repository.fetchActive());
  }

  Future<WarehouseAllocationResult> allocateWarehouse({
    required List<String> itemIds,
    required String warehouseCode,
    required bool overwriteExisting,
  }) async {
    final normalizedWarehouseCode =
        BobbinInventoryRecord.normalizeWarehouseCode(warehouseCode);
    if (normalizedWarehouseCode == null || itemIds.isEmpty) {
      return const WarehouseAllocationResult(
        updatedCount: 0,
        overwrittenCount: 0,
      );
    }

    final repository = ref.read(readingsRepositoryProvider);
    final activeItems = await repository.fetchActive();
    final selectedItems = activeItems
        .where((item) => itemIds.contains(item.id))
        .toList(growable: false);

    var updatedCount = 0;
    var overwrittenCount = 0;

    for (final item in selectedItems) {
      final inventoryRecord = BobbinInventoryRecord.fromItem(item);
      final currentWarehouseCode = inventoryRecord.warehouseCode;

      if (currentWarehouseCode == normalizedWarehouseCode) {
        continue;
      }
      if (inventoryRecord.hasWarehouseAllocated && !overwriteExisting) {
        continue;
      }

      await repository.updateCode(
        id: item.id,
        newCode: item.code,
        classification: _classify(item.code),
        metadataPayload: BobbinInventoryRecord.buildMetadata(
          lot: inventoryRecord.lot,
          warehouseCode: normalizedWarehouseCode,
          seed: item.metadataPayload,
        ),
      );
      updatedCount += 1;
      if (inventoryRecord.hasWarehouseAllocated) {
        overwrittenCount += 1;
      }
    }

    state = AsyncData(await repository.fetchActive());
    return WarehouseAllocationResult(
      updatedCount: updatedCount,
      overwrittenCount: overwrittenCount,
    );
  }

  ReadingClassification _classify(String code) {
    final classifier = ref.read(readingTypeClassifierProvider);
    return classifier.classify(code);
  }

  ReadingItem? _findItemById(List<ReadingItem> items, String id) {
    for (final item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }
}
