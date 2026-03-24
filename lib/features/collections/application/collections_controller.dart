import 'package:barcode_app/features/collections/data/collections_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final collectionsControllerProvider =
    AsyncNotifierProvider<CollectionsController, List<CollectionItem>>(
  CollectionsController.new,
);

final collectionItemProvider =
    FutureProvider.family<CollectionItem?, String>((ref, collectionId) {
  return ref.read(collectionsRepositoryProvider).findCollectionById(collectionId);
});

class CollectionsController extends AsyncNotifier<List<CollectionItem>> {
  @override
  Future<List<CollectionItem>> build() {
    return ref.read(collectionsRepositoryProvider).listCollections();
  }

  Future<CollectionItem> createCollection({
    required String title,
    required String companyId,
    required String createdBy,
  }) async {
    state = const AsyncLoading();
    final repository = ref.read(collectionsRepositoryProvider);
    final collection = await repository.createCollection(
      title: title,
      companyId: companyId,
      createdBy: createdBy,
    );
    state = await AsyncValue.guard(repository.listCollections);
    return collection;
  }
}
