import 'package:flutter/material.dart';
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
  late final MobileScannerController _controller = MobileScannerController(
    cameraResolution: const Size(1920, 1080),
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: _supportedLinearFormats,
  );
  bool _handlingDetection = false;

  void _handleDetection(BarcodeCapture capture) {
    if (_handlingDetection) {
      return;
    }

    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value.isEmpty) {
      return;
    }

    _handlingDetection = true;
    widget.onDetected(value);
    Navigator.of(context).pop();
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
                          const _ScannerHintCard(
                            message:
                                'Aproxime e alinhe o codigo na area central',
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
