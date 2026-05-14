import 'package:barcode_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra erro visivel quando bootstrap falha', (tester) async {
    await tester.pumpWidget(
      BootstrapFailureApp(
        error: StateError('SUPABASE_ANON_KEY ausente'),
      ),
    );

    expect(find.text('Falha ao iniciar o DelCod'), findsOneWidget);
    expect(find.textContaining('SUPABASE_ANON_KEY ausente'), findsOneWidget);
  });
}
