import 'package:barcode_app/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('inicia na rota de splash', (tester) async {
    await tester.pumpWidget(const BarcodeApp());

    expect(find.text('Inicializando...'), findsOneWidget);
  });
}
