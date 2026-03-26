import 'package:barcode_app/features/readings/domain/barcode_scan_consensus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  group('BarcodeScanConsensus', () {
    test('confirma somente apos leituras repetidas do mesmo valor', () {
      final consensus = BarcodeScanConsensus(requiredMatches: 2);

      final first = consensus.register(
        value: 'mg041125200739012',
        format: BarcodeFormat.code128,
      );
      final second = consensus.register(
        value: 'mg041125200739012',
        format: BarcodeFormat.code128,
      );

      expect(first, ScanConsensusDecision.pending);
      expect(second, ScanConsensusDecision.confirmed);
    });

    test('reinicia a contagem quando a leitura muda', () {
      final consensus = BarcodeScanConsensus(requiredMatches: 2);

      expect(
        consensus.register(
          value: 'mg041125200739012',
          format: BarcodeFormat.code128,
        ),
        ScanConsensusDecision.pending,
      );

      expect(
        consensus.register(
          value: 'mg041125200739099',
          format: BarcodeFormat.code128,
        ),
        ScanConsensusDecision.pending,
      );

      expect(
        consensus.register(
          value: 'mg041125200739099',
          format: BarcodeFormat.code128,
        ),
        ScanConsensusDecision.confirmed,
      );
    });

    test('rejeita EAN-13 com digito verificador invalido', () {
      final consensus = BarcodeScanConsensus(requiredMatches: 2);

      final decision = consensus.register(
        value: '7891234567890',
        format: BarcodeFormat.ean13,
      );

      expect(decision, ScanConsensusDecision.rejected);
    });

    test('aceita EAN-13 valido e confirma no segundo frame', () {
      final consensus = BarcodeScanConsensus(requiredMatches: 2);

      final first = consensus.register(
        value: '7891234567895',
        format: BarcodeFormat.ean13,
      );
      final second = consensus.register(
        value: '7891234567895',
        format: BarcodeFormat.ean13,
      );

      expect(first, ScanConsensusDecision.pending);
      expect(second, ScanConsensusDecision.confirmed);
    });
  });
}
