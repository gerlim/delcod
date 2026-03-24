import 'package:barcode_app/features/readings/domain/reading_input.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final readingsRepositoryProvider = Provider<ReadingsRepository>((ref) {
  return ReadingsRepository();
});

class ReadingsRepository {
  ReadingsRepository();

  final _uuid = const Uuid();
  final List<ReadingItem> _items = [];

  Future<bool> existsInCollection(String collectionId, String code) async {
    return _items.any((item) => item.collectionId == collectionId && item.code == code);
  }

  Future<void> saveReading(ReadingInput input) async {
    _items.add(
      ReadingItem(
        id: _uuid.v4(),
        collectionId: input.collectionId,
        code: input.code,
        source: input.source,
      ),
    );
  }

  Future<List<ReadingItem>> listByCollection(String collectionId) async {
    return _items.where((item) => item.collectionId == collectionId).toList(growable: false);
  }
}

class ReadingItem {
  const ReadingItem({
    required this.id,
    required this.collectionId,
    required this.code,
    required this.source,
  });

  final String id;
  final String collectionId;
  final String code;
  final String source;
}
