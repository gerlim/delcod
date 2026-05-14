import 'package:barcode_app/app/shell/shell_primitives.dart';
import 'package:barcode_app/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AuditStatusSummary extends StatelessWidget {
  const AuditStatusSummary({
    super.key,
    required this.importedCount,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.notFoundCount = 0,
    this.pendingCount,
  });

  final int importedCount;
  final int correctCount;
  final int incorrectCount;
  final int notFoundCount;
  final int? pendingCount;

  @override
  Widget build(BuildContext context) {
    final resolvedPending = pendingCount ??
        (importedCount - correctCount - incorrectCount).clamp(0, importedCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final itemWidth = compact
            ? (constraints.maxWidth - 12) / 2
            : (constraints.maxWidth - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _metric(
              width: itemWidth,
              label: 'Corretos',
              value: '$correctCount',
              icon: Icons.check_circle_outline,
              color: AppColors.safeGreen,
            ),
            _metric(
              width: itemWidth,
              label: 'Incorretos',
              value: '$incorrectCount',
              icon: Icons.error_outline,
              color: AppColors.faultRed,
            ),
            _metric(
              width: itemWidth,
              label: 'Nao encontrados',
              value: '$notFoundCount',
              icon: Icons.warning_amber_outlined,
              color: AppColors.alertAmber,
            ),
            _metric(
              width: itemWidth,
              label: 'Pendentes',
              value: '$resolvedPending',
              icon: Icons.pending_actions_outlined,
              color: AppColors.signalTeal,
            ),
          ],
        );
      },
    );
  }

  Widget _metric({
    required double width,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: width.clamp(150, 260).toDouble(),
      child: MetricCard(
        label: label,
        value: value,
        icon: icon,
        emphasisColor: color,
      ),
    );
  }
}
