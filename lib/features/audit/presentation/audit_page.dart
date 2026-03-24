import 'package:barcode_app/app/shell/shell_primitives.dart';
import 'package:barcode_app/app/theme/app_colors.dart';
import 'package:barcode_app/features/audit/data/audit_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuditPage extends ConsumerWidget {
  const AuditPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(auditEventsProvider);

    return ListView(
      children: [
        const SectionHeader(
          title: 'Auditoria',
          subtitle:
              'Acompanhe eventos criticos, exclusoes e rastreabilidade operacional.',
        ),
        const SizedBox(height: 20),
        events.when(
          data: (items) {
            if (items.isEmpty) {
              return const SectionCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('Nenhum evento de auditoria')),
                ),
              );
            }

            return SectionCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card.outlined(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: Container(
                        decoration: BoxDecoration(
                          color: AppColors.signalTeal.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: const Icon(
                          Icons.policy_outlined,
                          color: AppColors.signalTeal,
                        ),
                      ),
                      title: Text('${item.action.name} ${item.targetType}'),
                      subtitle: Text('${item.actorId} -> ${item.targetId}'),
                      trailing: Text(item.timestamp.toIso8601String()),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) =>
              const Center(child: Text('Falha ao carregar auditoria')),
        ),
      ],
    );
  }
}
