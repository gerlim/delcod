import 'package:flutter/foundation.dart';

enum SyncStatus {
  offline,
  syncing,
  synced,
  failed,
}

@immutable
class SyncLogEntry {
  const SyncLogEntry({
    required this.occurredAt,
    required this.status,
    required this.message,
  });

  final DateTime occurredAt;
  final SyncStatus status;
  final String message;
}
