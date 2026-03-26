import 'package:flutter/material.dart';
import 'package:barcode_app/features/readings/domain/barcode_scan_consensus.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

const List<BarcodeFormat> _supportedLinearFormats = <BarcodeFormat>[
  BarcodeFormat.code128,
  BarcodeFormat.code39,
  BarcodeFormat.code93,
  BarcodeFormat.codabar,
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.itf,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
];

class AndroidScannerView extends StatefulWidget {
  const AndroidScannerView({
    super.key,
    required this.onDetected,
  });

  final ValueChanged<String> onDetected;

  @override
  State<AndroidScannerView> createState() => _AndroidScannerViewState();
}

class _AndroidScannerViewState extends State<AndroidScannerView> {
  bool _isOpen = false;

  Future<void> _openScanner() async {
    setState(() => _isOpen = true);

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) {
          return _ScannerScreen(
            onDetected: widget.onDetected,
          );
        },
        fullscreenDialog: true,
      ),
    );

    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _isOpen ? null : _openScanner,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Abrir scanner'),
      ),
    );
  }
}

class _ScannerScreen extends StatefulWidget {
  const _ScannerScreen({
    required this.onDetected,
  });

  final ValueChanged<String> onDetected;

  @override
  State<_ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<_ScannerScreen> {
  static const String _defaultHintMessage =
      'Aproxime e alinhe o codigo na area central';
  static const String _holdStillHintMessage =
      'Leitura detectada. Mantenha o codigo parado por um instante';
  static const String _retryHintMessage =
      'Leitura instavel. Ajuste a distancia ou use a lanterna';

  late final MobileScannerController _controller = MobileScannerController(
    cameraResolution: const Size(1920, 1080),
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: _supportedLinearFormats,
  );
  final BarcodeScanConsensus _consensus = BarcodeScanConsensus(
    requiredMatches: 2,
  );
  bool _handlingDetection = false;
  String _hintMessage = _defaultHintMessage;

  void _handleDetection(BarcodeCapture capture) {
    if (_handlingDetection) {
      return;
    }

    final candidate = _selectBestBarcode(capture.barcodes);
    final value = candidate?.rawValue ?? candidate?.displayValue;
    if (value == null || value.isEmpty) {
      return;
    }

    final decision = _consensus.register(
      value: value,
      format: candidate!.format,
    );

    switch (decision) {
      case ScanConsensusDecision.rejected:
        if (mounted && _hintMessage != _retryHintMessage) {
          setState(() => _hintMessage = _retryHintMessage);
        }
        return;
      case ScanConsensusDecision.pending:
        if (mounted && _hintMessage != _holdStillHintMessage) {
          setState(() => _hintMessage = _holdStillHintMessage);
        }
        return;
      case ScanConsensusDecision.confirmed:
        final confirmedValue = _consensus.currentValue;
        if (confirmedValue == null || confirmedValue.isEmpty) {
          return;
        }

        _handlingDetection = true;
        widget.onDetected(confirmedValue);
        Navigator.of(context).pop();
    }
  }

  Barcode? _selectBestBarcode(List<Barcode> barcodes) {
    final candidates = barcodes
        .where((barcode) => _supportedLinearFormats.contains(barcode.format))
        .where((barcode) {
          final rawValue = barcode.rawValue ?? barcode.displayValue;
          return rawValue != null && rawValue.trim().isNotEmpty;
        })
        .toList(growable: false);

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort((left, right) {
      final leftArea = left.size.width * left.size.height;
      final rightArea = right.size.width * right.size.height;
      return rightArea.compareTo(leftArea);
    });

    return candidates.first;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scanWindow = Rect.fromCenter(
            center: constraints.biggest.center(Offset.zero),
            width: constraints.maxWidth * 0.82,
            height: constraints.maxHeight * 0.28,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _controller,
                fit: BoxFit.cover,
                scanWindow: scanWindow,
                onDetect: _handleDetection,
              ),
              _ScannerOverlay(scanWindow: scanWindow),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _ScannerHintCard(
                            message: _hintMessage,
                          ),
                          Row(
                            children: [
                              ValueListenableBuilder<MobileScannerState>(
                                valueListenable: _controller,
                                builder: (context, scannerState, _) {
                                  final torchState = scannerState.torchState;
                                  final torchEnabled =
                                      torchState == TorchState.on;
                                  return IconButton.filledTonal(
                                    tooltip: 'Alternar lanterna',
                                    onPressed: _controller.toggleTorch,
                                    icon: Icon(
                                      torchEnabled
                                          ? Icons.flash_on
                                          : Icons.flash_off,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                tooltip: 'Fechar scanner',
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScannerHintCard extends StatelessWidget {
  const _ScannerHintCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay({
    required this.scanWindow,
  });

  final Rect scanWindow;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.38),
              ),
            ),
          ),
          Positioned.fromRect(
            rect: scanWindow,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.92),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
