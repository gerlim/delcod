import 'package:mobile_scanner/mobile_scanner.dart';

enum ScanConsensusDecision {
  rejected,
  pending,
  confirmed,
}

class BarcodeScanConsensus {
  BarcodeScanConsensus({
    this.requiredMatches = 2,
  }) : assert(requiredMatches > 0, 'requiredMatches must be greater than 0.');

  final int requiredMatches;

  String? _currentValue;
  BarcodeFormat? _currentFormat;
  int _matches = 0;

  String? get currentValue => _currentValue;

  void reset() {
    _currentValue = null;
    _currentFormat = null;
    _matches = 0;
  }

  ScanConsensusDecision register({
    required String value,
    required BarcodeFormat format,
  }) {
    final normalizedValue = _normalizeValue(value);
    if (normalizedValue.isEmpty) {
      reset();
      return ScanConsensusDecision.rejected;
    }

    if (!_isFormatValuePlausible(normalizedValue, format)) {
      reset();
      return ScanConsensusDecision.rejected;
    }

    if (_currentValue == normalizedValue && _currentFormat == format) {
      _matches += 1;
    } else {
      _currentValue = normalizedValue;
      _currentFormat = format;
      _matches = 1;
    }

    return _matches >= requiredMatches
        ? ScanConsensusDecision.confirmed
        : ScanConsensusDecision.pending;
  }

  static String _normalizeValue(String value) {
    return value.replaceAll(RegExp(r'\s+'), '').trim();
  }

  static bool _isFormatValuePlausible(String value, BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.ean13:
        return _hasValidModulo10CheckDigit(value, expectedLength: 13);
      case BarcodeFormat.ean8:
        return _hasValidModulo10CheckDigit(value, expectedLength: 8);
      case BarcodeFormat.upcA:
        return _hasValidModulo10CheckDigit(value, expectedLength: 12);
      case BarcodeFormat.itf:
        return value.length.isEven && RegExp(r'^\d+$').hasMatch(value);
      case BarcodeFormat.code39:
      case BarcodeFormat.code93:
      case BarcodeFormat.code128:
      case BarcodeFormat.codabar:
      case BarcodeFormat.upcE:
      case BarcodeFormat.unknown:
      case BarcodeFormat.all:
      case BarcodeFormat.dataMatrix:
      case BarcodeFormat.qrCode:
      case BarcodeFormat.pdf417:
      case BarcodeFormat.aztec:
        return value.isNotEmpty;
    }
  }

  static bool _hasValidModulo10CheckDigit(
    String value, {
    required int expectedLength,
  }) {
    if (value.length != expectedLength || !RegExp(r'^\d+$').hasMatch(value)) {
      return false;
    }

    final digits = value.split('').map(int.parse).toList(growable: false);
    final payload = digits.sublist(0, digits.length - 1);
    final checkDigit = digits.last;

    final weightedSum = payload.reversed.toList().asMap().entries.fold<int>(
      0,
      (sum, entry) {
        final weight = entry.key.isEven ? 3 : 1;
        return sum + (entry.value * weight);
      },
    );

    final expectedCheckDigit = (10 - (weightedSum % 10)) % 10;
    return checkDigit == expectedCheckDigit;
  }
}
