import 'dart:async';

import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/duplicate_decision.dart';
import 'package:barcode_app/features/readings/domain/import_commit_result.dart';
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

    await repository.addCode(
      code: normalized,
      source: source,
    );
    state = AsyncData(await repository.fetchActive());
    return DuplicateDecision.saved;
  }

  Future<DuplicateDecision> updateCode({
    required String id,
    required String newCode,
    bool forceDuplicate = false,
  }) async {
    final normalized = newCode.trim();
    if (normalized.isEmpty) {
      return DuplicateDecision.saved;
    }

    final repository = ref.read(readingsRepositoryProvider);
    final exists = await repository.existsCode(
      normalized,
      excludingId: id,
    );
    if (exists && !forceDuplicate) {
      return DuplicateDecision.warning;
    }

    await repository.updateCode(
      id: id,
      newCode: normalized,
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
    final normalizedCodes = codes
        .map((code) => code.replaceAll(RegExp(r'\s+'), '').trim())
        .where((code) => code.isNotEmpty)
        .toList(growable: false);

    if (normalizedCodes.isEmpty) {
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
    var skippedDuplicates = 0;

    for (final code in normalizedCodes) {
      final duplicate =
          existingCodes.contains(code) || seenInImport.contains(code);

      if (duplicate) {
        if (includeDuplicates) {
          codesToImport.add(code);
        } else {
          skippedDuplicates += 1;
        }
        continue;
      }

      seenInImport.add(code);
      codesToImport.add(code);
    }

    if (codesToImport.isNotEmpty) {
      await repository.addCodesBatch(
        codes: codesToImport,
        source: 'import',
      );
    }

    state = AsyncData(await repository.fetchActive());
    return ImportCommitResult(
      importedCount: codesToImport.length,
      skippedDuplicates: includeDuplicates ? 0 : skippedDuplicates,
    );
  }
}
