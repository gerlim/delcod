import 'package:barcode_app/features/readings/application/readings_controller.dart';
import 'package:barcode_app/features/readings/data/readings_repository.dart';
import 'package:barcode_app/features/readings/domain/duplicate_decision.dart';
import 'package:barcode_app/features/readings/domain/reading_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('retorna aviso de duplicidade quando o código já existe na coleta', () async {
    final repository = ReadingsRepository();
    await repository.saveReading(
      const ReadingInput(
        collectionId: 'collection-1',
        code: '7891234567890',
        source: 'camera',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        readingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(readingsControllerProvider('collection-1').future);
    final decision = await container
        .read(readingsControllerProvider('collection-1').notifier)
        .registerReading(
          const ReadingInput(
            collectionId: 'collection-1',
            code: '7891234567890',
            source: 'camera',
          ),
        );

    expect(decision, DuplicateDecision.warning);
  });
}
