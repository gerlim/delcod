import 'package:barcode_app/features/collections/data/collections_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final collectionsControllerProvider =
    AsyncNotifierProvider<CollectionsController, List<CollectionItem>>(
  CollectionsController.new,
);

class CollectionsController extends AsyncNotifier<List<CollectionItem>> {
  @override
  Future<List<CollectionItem>> build() {
    return ref.read(collectionsRepositoryProvider).listCollections();
  }

  Future<void> createCollection({
    required String title,
    required String companyId,
    required String createdBy,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(collectionsRepositoryProvider);
      await repository.createCollection(
        title: title,
        companyId: companyId,
        createdBy: createdBy,
      );
      return repository.listCollections();
    });
  }
}
