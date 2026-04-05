import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return AuditRepository();
});

final auditEventsProvider = FutureProvider<List<AuditEvent>>((ref) {
  return ref.read(auditRepositoryProvider).listEvents();
});

class AuditRepository {
  AuditRepository();

  final _uuid = const Uuid();
  final List<AuditEvent> _events = [];

  Future<void> recordCreate({
    required String actorId,
    required String targetId,
    required String targetType,
  }) {
    return _append(
      AuditAction.create,
      actorId: actorId,
      targetId: targetId,
      targetType: targetType,
    );
  }

  Future<void> recordEdit({
    required String actorId,
    required String targetId,
    required String targetType,
  }) {
    return _append(
      AuditAction.edit,
      actorId: actorId,
      targetId: targetId,
      targetType: targetType,
    );
  }

  Future<void> recordDelete({
    required String actorId,
    required String targetId,
    required String targetType,
  }) {
    return _append(
      AuditAction.delete,
      actorId: actorId,
      targetId: targetId,
      targetType: targetType,
    );
  }

  Future<void> recordCloseCollection({
    required String actorId,
    required String targetId,
  }) {
    return _append(
      AuditAction.closeCollection,
      actorId: actorId,
      targetId: targetId,
      targetType: 'collection',
    );
  }

  Future<List<AuditEvent>> listEvents() async {
    return List.unmodifiable(_events);
  }

  Future<void> _append(
    AuditAction action, {
    required String actorId,
    required String targetId,
    required String targetType,
  }) async {
    _events.add(
      AuditEvent(
        id: _uuid.v4(),
        actorId: actorId,
        action: action,
        targetId: targetId,
        targetType: targetType,
        timestamp: DateTime.now(),
      ),
    );
  }
}

enum AuditAction {
  create,
  edit,
  delete,
  closeCollection,
}

class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.actorId,
    required this.action,
    required this.targetId,
    required this.targetType,
    required this.timestamp,
  });

  final String id;
  final String actorId;
  final AuditAction action;
  final String targetId;
  final String targetType;
  final DateTime timestamp;
}

