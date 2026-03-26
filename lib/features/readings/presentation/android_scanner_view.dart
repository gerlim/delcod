import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            fit: BoxFit.cover,
            onDetect: _handleDetection,
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: IconButton.filledTonal(
                  tooltip: 'Fechar scanner',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
