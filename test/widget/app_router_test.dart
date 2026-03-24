import 'package:barcode_app/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('inicia na tela de login quando não há sessão', (tester) async {
    await tester.pumpWidget(const BarcodeApp());

    expect(find.text('Entrar'), findsOneWidget);
  });
}
