import 'package:barcode_app/features/readings/domain/reading_item.dart';

abstract final class ReadingSyncMergePolicy {
  static ReadingItem resolve({
    required ReadingItem? current,
    required ReadingItem remote,
    required bool hasPendingMutation,
  }) {
    if (current == null) {
      return remote;
    }

    // When there is no local mutation waiting to be sent, the remote snapshot
    // is the source of truth and must heal stale local cache state.
    if (!hasPendingMutation) {
      return remote;
    }

    if (remote.updatedAt.isAfter(current.updatedAt)) {
      return remote;
    }

    return current;
  }
}
