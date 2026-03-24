import 'package:barcode_app/features/collections/application/collections_controller.dart';
import 'package:barcode_app/features/collections/data/collections_repository.dart';
import 'package:barcode_app/features/collections/domain/collection_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('cria uma nova coleta com status open', () async {
    final repository = CollectionsRepository();
    final container = ProviderContainer(
      overrides: [
        collectionsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(collectionsControllerProvider.future);
    await container.read(collectionsControllerProvider.notifier).createCollection(
          title: 'Coleta Expedição 01',
          companyId: 'company-a',
          createdBy: 'user-1',
        );

    final collections = container.read(collectionsControllerProvider).valueOrNull ?? [];

    expect(collections, hasLength(1));
    expect(collections.single.status, CollectionStatus.open);
  });
}
