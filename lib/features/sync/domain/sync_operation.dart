class SyncOperation {
  const SyncOperation({
    required this.id,
    required this.entity,
    required this.operation,
    required this.payload,
  });

  final String id;
  final String entity;
  final String operation;
  final String payload;
}
