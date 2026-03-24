import 'package:barcode_app/features/audit/data/audit_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registra eventos de exclusão com ator e alvo', () async {
    final repository = AuditRepository();

    await repository.recordDelete(
      actorId: 'user-1',
      targetId: 'reading-1',
      targetType: 'reading',
    );

    final events = await repository.listEvents();

    expect(events, hasLength(1));
    expect(events.single.actorId, 'user-1');
    expect(events.single.targetId, 'reading-1');
    expect(events.single.action, AuditAction.delete);
  });
}
