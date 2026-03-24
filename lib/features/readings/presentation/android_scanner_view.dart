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

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: MobileScanner(
            onDetect: (capture) {
              final value = capture.barcodes.firstOrNull?.rawValue;
              if (value != null && value.isNotEmpty) {
                widget.onDetected(value);
                Navigator.of(context).pop();
              }
            },
          ),
        );
      },
    );

    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _isOpen ? null : _openScanner,
      icon: const Icon(Icons.qr_code_scanner),
      label: const Text('Abrir scanner'),
    );
  }
}
