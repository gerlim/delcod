import 'package:barcode_app/app/shell/shell_primitives.dart';
import 'package:barcode_app/app/theme/app_colors.dart';
import 'package:barcode_app/features/app_update/application/app_update_controller.dart';
import 'package:flutter/material.dart';

class AppUpdateBanner extends StatelessWidget {
  const AppUpdateBanner({
    super.key,
    required this.state,
    required this.onUpdateNow,
    required this.onDismiss,
    required this.onRetry,
  });

  final AppUpdateState state;
  final Future<void> Function() onUpdateNow;
  final VoidCallback onDismiss;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.system_update_alt_rounded,
                color: AppColors.signalTeal,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_statusChip case final chip?) chip,
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.steel,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (state.downloadProgress != null &&
              state.status == AppUpdateStatus.downloading) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: state.downloadProgress!.clamp(0, 1),
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: AppColors.mist,
              color: AppColors.signalTeal,
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: switch (state.status) {
              AppUpdateStatus.available => [
                  FilledButton.icon(
                    onPressed: onUpdateNow,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Atualizar agora'),
                  ),
                  FilledButton.tonal(
                    onPressed: onDismiss,
                    child: const Text('Depois'),
                  ),
                ],
              AppUpdateStatus.failed => [
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tentar novamente'),
                  ),
                  TextButton(
                    onPressed: onDismiss,
                    child: const Text('Depois'),
                  ),
                ],
              _ => [
                  FilledButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.hourglass_top_rounded),
                    label: Text(_actionLabel),
                  ),
                ],
            },
          ),
        ],
      ),
    );
  }

  String get _title {
    switch (state.status) {
      case AppUpdateStatus.downloading:
        return 'Baixando atualizacao';
      case AppUpdateStatus.installing:
        return 'Instalando atualizacao';
      case AppUpdateStatus.failed:
        return 'Falha ao atualizar';
      case AppUpdateStatus.available:
      default:
        return 'Nova versao disponivel';
    }
  }

  String get _message {
    final manifest = state.availableManifest;
    switch (state.status) {
      case AppUpdateStatus.available:
        return manifest == null
            ? 'Uma nova versao do DelCod esta pronta para instalar.'
            : 'Versao ${manifest.versionName} disponivel para o DelCod.';
      case AppUpdateStatus.downloading:
        return 'A nova versao esta sendo baixada no aparelho.';
      case AppUpdateStatus.installing:
        return 'O Android vai abrir a confirmacao final de instalacao.';
      case AppUpdateStatus.failed:
        return state.lastError ??
            'Nao foi possivel concluir a atualizacao agora.';
      default:
        return '';
    }
  }

  String get _actionLabel {
    switch (state.status) {
      case AppUpdateStatus.downloading:
        return 'Baixando...';
      case AppUpdateStatus.installing:
        return 'Abrindo instalador...';
      default:
        return 'Aguarde';
    }
  }

  Widget? get _statusChip {
    switch (state.status) {
      case AppUpdateStatus.available:
        return const StatusChip(
          label: 'Update disponivel',
          color: AppColors.signalTeal,
          icon: Icons.system_update_alt_rounded,
        );
      case AppUpdateStatus.failed:
        return const StatusChip(
          label: 'Falha',
          color: AppColors.faultRed,
          icon: Icons.warning_amber_rounded,
        );
      case AppUpdateStatus.downloading:
      case AppUpdateStatus.installing:
        return const StatusChip(
          label: 'Atualizando',
          color: AppColors.alertAmber,
          icon: Icons.downloading_rounded,
        );
      default:
        return null;
    }
  }
}
