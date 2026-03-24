import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/duplicate_decision.dart';
import 'package:barcode_app/features/readings/domain/reading_input.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final readingsControllerProvider = AsyncNotifierProviderFamily<
    ReadingsController, List<ReadingItem>, String>(ReadingsController.new);

class ReadingsController extends FamilyAsyncNotifier<List<ReadingItem>, String> {
  @override
  Future<List<ReadingItem>> build(String arg) {
    return ref.read(readingsRepositoryProvider).listByCollection(arg);
  }

  Future<DuplicateDecision> registerReading(ReadingInput input) async {
    final repository = ref.read(readingsRepositoryProvider);
    final exists = await repository.existsInCollection(input.collectionId, input.code);

    if (exists) {
      return DuplicateDecision.warning;
    }

    await repository.saveReading(input);
    state = AsyncData(await repository.listByCollection(input.collectionId));
    return DuplicateDecision.saved;
  }
}
