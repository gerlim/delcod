import 'package:barcode_app/features/collections/application/collections_controller.dart';
import 'package:barcode_app/features/sync/presentation/sync_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CollectionsPage extends ConsumerWidget {
  const CollectionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coletas'),
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),
          Expanded(
            child: collections.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('Nenhuma coleta criada'));
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item.title),
                      subtitle: Text(item.status.name),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Falha ao carregar coletas')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Nova coleta'),
      ),
    );
  }
}
