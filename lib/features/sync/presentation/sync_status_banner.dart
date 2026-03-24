import 'package:barcode_app/app/theme/app_colors.dart';
import 'package:barcode_app/features/sync/application/sync_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncControllerProvider);
    final color = _accentColor(syncState.status);
    final background = _backgroundColor(syncState.status);
    final detail = syncState.pendingCount == 0
        ? 'Sem pendencias'
        : '${syncState.pendingCount} operacoes aguardando envio';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(
              _statusIcon(syncState.status),
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  syncState.label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.steel,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.offline:
        return Icons.cloud_off_outlined;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.synced:
        return Icons.cloud_done_outlined;
      case SyncStatus.failed:
        return Icons.error_outline;
    }
  }

  Color _accentColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.offline:
        return AppColors.steel;
      case SyncStatus.syncing:
        return AppColors.alertAmber;
      case SyncStatus.synced:
        return AppColors.safeGreen;
      case SyncStatus.failed:
        return AppColors.faultRed;
    }
  }

  Color _backgroundColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.offline:
        return const Color(0xFFF1F4F6);
      case SyncStatus.syncing:
        return const Color(0xFFFFF3E0);
      case SyncStatus.synced:
        return const Color(0xFFE8F5E9);
      case SyncStatus.failed:
        return const Color(0xFFFDECEC);
    }
  }
}
