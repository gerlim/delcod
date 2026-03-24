import 'package:barcode_app/features/collections/domain/collection_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final collectionsRepositoryProvider = Provider<CollectionsRepository>((ref) {
  return CollectionsRepository();
});

class CollectionsRepository {
  CollectionsRepository();

  final _uuid = const Uuid();
  final List<CollectionItem> _items = [];

  Future<List<CollectionItem>> listCollections() async {
    return List.unmodifiable(_items);
  }

  Future<CollectionItem> createCollection({
    required String title,
    required String companyId,
    required String createdBy,
  }) async {
    final item = CollectionItem(
      id: _uuid.v4(),
      companyId: companyId,
      title: title,
      status: CollectionStatus.open,
      createdBy: createdBy,
    );
    _items.add(item);
    return item;
  }

  Future<CollectionItem?> findCollectionById(String id) async {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }
}

class CollectionItem {
  const CollectionItem({
    required this.id,
    required this.companyId,
    required this.title,
    required this.status,
    required this.createdBy,
  });

  final String id;
  final String companyId;
  final String title;
  final CollectionStatus status;
  final String createdBy;
}
