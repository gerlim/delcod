import 'package:barcode_app/core/platform/platform_capabilities.dart';
import 'package:barcode_app/features/readings/application/readings_controller.dart';
import 'package:barcode_app/features/readings/domain/reading_input.dart';
import 'package:barcode_app/features/readings/presentation/android_scanner_view.dart';
import 'package:barcode_app/features/readings/presentation/manual_entry_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReadingsPage extends ConsumerWidget {
  const ReadingsPage({
    super.key,
    required this.collectionId,
    required this.collectionTitle,
  });

  final String collectionId;
  final String collectionTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readings = ref.watch(readingsControllerProvider(collectionId));
    final capabilities = ref.watch(platformCapabilitiesProvider);
    final count = readings.valueOrNull?.length ?? 0;

    Future<void> registerReading(String code, String source) async {
      final decision = await ref.read(readingsControllerProvider(collectionId).notifier).registerReading(
            ReadingInput(
              collectionId: collectionId,
              code: code,
              source: source,
            ),
          );

      if (!context.mounted) {
        return;
      }

      if (decision.name == 'warning') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código já lido nesta coleta'),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(collectionTitle),
      ),
      body: readings.when(
        data: (items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: capabilities.supportsCameraScanning
                  ? AndroidScannerView(
                      onDetected: (value) => registerReading(value, 'camera'),
                    )
                  : ManualEntryForm(
                      onSubmit: (value) => registerReading(value, 'manual'),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Total: $count'),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('Nenhuma leitura registrada'))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Dismissible(
                          key: ValueKey(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(color: Colors.red),
                          child: ListTile(
                            title: Text(item.code),
                            subtitle: Text(item.source),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Falha ao carregar leituras')),
      ),
    );
  }
}
