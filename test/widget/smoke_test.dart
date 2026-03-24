import 'package:barcode_app/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza a shell do app', (tester) async {
    await tester.pumpWidget(const BarcodeApp());

    expect(find.text('Barcode App'), findsOneWidget);
  });
}
