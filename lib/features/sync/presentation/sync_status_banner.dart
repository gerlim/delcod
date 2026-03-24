import 'package:barcode_app/features/sync/application/sync_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncControllerProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: _backgroundColor(syncState.status),
      child: Text(
        syncState.label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Color _backgroundColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.offline:
        return Colors.grey.shade700;
      case SyncStatus.syncing:
        return Colors.orange.shade700;
      case SyncStatus.synced:
        return Colors.green.shade700;
      case SyncStatus.failed:
        return Colors.red.shade700;
    }
  }
}
