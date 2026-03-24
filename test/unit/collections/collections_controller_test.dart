import 'package:barcode_app/features/collections/application/collections_controller.dart';
import 'package:barcode_app/features/collections/data/collections_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cria coleta e devolve o item criado', () async {
    final repository = CollectionsRepository();
    final container = ProviderContainer(
      overrides: [
        collectionsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final created = await container
        .read(collectionsControllerProvider.notifier)
        .createCollection(
          title: 'Coleta de expedicao',
          companyId: 'company-a',
          createdBy: 'user-1',
        );

    final collections = await container.read(collectionsControllerProvider.future);

    expect(created.title, 'Coleta de expedicao');
    expect(collections, hasLength(1));
    expect(collections.single.id, created.id);
  });
}
