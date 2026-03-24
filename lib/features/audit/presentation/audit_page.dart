import 'package:barcode_app/features/audit/data/audit_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuditPage extends ConsumerWidget {
  const AuditPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(auditEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoria'),
      ),
      body: events.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Nenhum evento de auditoria'));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text('${item.action.name} ${item.targetType}'),
                subtitle: Text('${item.actorId} -> ${item.targetId}'),
                trailing: Text(item.timestamp.toIso8601String()),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Falha ao carregar auditoria')),
      ),
    );
  }
}
